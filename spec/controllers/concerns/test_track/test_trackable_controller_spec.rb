require 'rails_helper'

RSpec.describe TestTrack::Controller do
  mixin = described_class

  controller(ApplicationController) do
    include mixin
    require_feature_flag :cool_feature_enabled

    self.test_track_identity = :current_clown

    def index
      render json: {
        v1_split_registry: test_track_web_session.state_hash[:registry],
        assignments: test_track_web_session.state_hash[:assignments]
      }
    end

    def show
      test_track_visitor.ab 'time', 'beer_thirty'
      head :no_content
    end

    private

    def current_clown; end
  end

  def response_json
    @response_json ||= JSON.parse(response.body)
  end

  let(:existing_visitor_id) { SecureRandom.uuid }
  let(:split_registry) do
    {
      'splits' =>
      {
        'time' => { 'weights' => { 'beer_thirty' => 100 }, 'feature_gate' => false },
        'cool_feature_enabled' => { 'weights' => { 'true' => 0, 'false' => 100 }, 'feature_gate' => true }
      },
      'experience_sampling_weight' => 1
    }
  end
  let(:remote_visitor) do
    {
      id: existing_visitor_id,
      assignments: [
        { split_name: 'time', variant: 'beer_thirty', unsynced: false },
        { split_name: 'cool_feature_enabled', variant: true, unsynced: false }
      ]
    }
  end
  let(:visitor_dsl) { instance_double(TestTrack::VisitorDSL, ab: true) }

  before do
    allow(TestTrack::Remote::SplitRegistry).to receive(:to_hash).and_return(split_registry)
    allow(TestTrack::Remote::Visitor).to receive(:fake_instance_attributes).and_return(remote_visitor)
    allow(TestTrack::VisitorDSL).to receive(:new).and_return(visitor_dsl)
    allow(RequestStore).to receive(:[]=).and_return(visitor_dsl)
  end

  describe ".test_track_identity class attribute" do
    it "holds a test_track_identity" do
      subject.class.test_track_identity = :current_user
      expect(subject.class.test_track_identity).to eq :current_user
    end
  end

  it "responds with the action's usual http status" do
    get :index
    expect(response).to have_http_status(:ok)
  end

  it "returns the split registry" do
    get :index
    expect(response_json['v1_split_registry']).to eq(
      'cool_feature_enabled' => { 'false' => 100, 'true' => 0 },
      'time' => { 'beer_thirty' => 100 }
    )
  end

  it "returns an empty assignment hash for a generated visitor" do
    get :index
    expect(response_json['assignments']).to eq({})
    expect(TestTrack::Remote::Visitor).not_to have_received(:fake_instance_attributes)
  end

  it "returns a server-provided assignment hash for an existing visitor" do
    request.cookies['tt_visitor_id'] = existing_visitor_id
    get :index
    expect(response_json['assignments']).to eq("time" => "beer_thirty", "cool_feature_enabled" => true)
  end

  it "sets a UUID tt_visitor_id cookie if unset" do
    expect(request.cookies['tt_visitor_id']).to eq nil
    get :index
    expect(response.cookies['tt_visitor_id']).to match(/[0-9a-f\-]{36}/)
  end

  it "preserves tt_visitor_id cookie if set" do
    request.cookies['tt_visitor_id'] = existing_visitor_id
    get :index
    expect(response.cookies['tt_visitor_id']).to eq existing_visitor_id
  end

  it "exposes the VisitorDSL to the controller" do
    allow(TestTrack::VisitorDSL).to receive(:new).and_return(visitor_dsl)
    get :show, id: "1234"
    expect(visitor_dsl).to have_received(:ab).with('time', 'beer_thirty')
    expect(response).to have_http_status(:no_content)
  end

  it "stores the session in RequestStore" do
    get :show, id: "1234"
    expect(RequestStore).to have_received(:[]=).with(:test_track_web_session, instance_of(TestTrack::WebSession))
  end

  it "raises a RoutingError when a feature flag is required and the ab value is false" do
    allow(TestTrack::VisitorDSL).to receive(:new).and_return(
      instance_double(TestTrack::VisitorDSL, ab: false)
    )
    expect { get :index }.to raise_error ActionController::RoutingError, 'Not Found'
  end
end
