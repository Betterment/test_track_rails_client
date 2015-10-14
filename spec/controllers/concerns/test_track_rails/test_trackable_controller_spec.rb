require 'rails_helper'

RSpec.describe TestTrackRails::TestTrackableController do
  mixin = described_class

  controller(ApplicationController) do
    include mixin

    def index
      render json: { tt_split_registry: tt_split_registry, tt_assignment_registry: tt_assignment_registry }
    end
  end

  def response_json
    @response_json ||= JSON.parse(response.body).with_indifferent_access
  end

  let(:existing_visitor_id) { SecureRandom.uuid }
  let(:split_registry) { { 'time' => { 'beer_thirty' => 100 } } }
  let(:assignment_registry) { { 'time' => 'beer_thirty' } }

  it "responds with the action's usual http status" do
    get :index
    expect(response).to have_http_status(:ok)
  end

  it "returns the split registry" do
    allow(TestTrackRails::SplitRegistry).to receive(:fake_instance_attributes).and_return(split_registry)
    get :index
    expect(response_json[:tt_split_registry]).to eq(split_registry)
  end

  it "returns an empty assignment registry for a generated visitor" do
    allow(TestTrackRails::AssignmentRegistry).to receive(:fake_instance_attributes).and_return(assignment_registry)
    get :index
    expect(response_json[:tt_assignment_registry]).to eq({})
    expect(TestTrackRails::AssignmentRegistry).not_to have_received(:fake_instance_attributes)
  end

  it "returns a server-provided assignment registry for an existing visitor" do
    request.cookies['tt_visitor_id'] = existing_visitor_id
    allow(TestTrackRails::AssignmentRegistry).to receive(:fake_instance_attributes).and_return(assignment_registry)
    get :index
    expect(response_json[:tt_assignment_registry]).to eq(assignment_registry)
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

  context "with cookie registry stubbed" do
    let(:cookie_registry) { double(:cookie_registry, "[]" => nil, permanent: permanent_cookie_registry, "[]=" => nil) }
    let(:permanent_cookie_registry) { double(:permanent_cookie_registry, "[]=" => nil) }

    attr_reader :cookie_assignments

    def expect_permanent_cookie_opts(name, opts)
      expect(permanent_cookie_registry).to have_received("[]=").with(name, hash_including(opts))
    end

    before do
      allow(subject).to receive(:cookies).and_return(cookie_registry)
    end

    it "doesn't set a non-permanent cookie" do
      get :index
      expect(cookie_registry).not_to have_received("[]=")
    end

    it "sets cookie domain to the request's second-level domain" do
      request.host = "jar.jar.binx.com"
      get :index
      expect_permanent_cookie_opts(:tt_visitor_id, domain: ".binx.com")
    end

    it "sets the secure flag if the request is https" do
      allow(request).to receive(:ssl?).and_return(true)
      get :index
      expect_permanent_cookie_opts(:tt_visitor_id, secure: true)
    end

    it "doesn't set the secure flag if the request is http" do
      allow(request).to receive(:ssl?).and_return(false)
      get :index
      expect_permanent_cookie_opts(:tt_visitor_id, secure: false)
    end

    it "doesn't set the httponly flag" do
      get :index
      expect_permanent_cookie_opts(:tt_visitor_id, httponly: false)
    end
  end
end
