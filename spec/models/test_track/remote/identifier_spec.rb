require 'rails_helper'

RSpec.describe TestTrack::Remote::Identifier do
  let(:params) { { identifier_type: "clown_id", visitor_id: "fake_visitor_id", value: 1234 } }
  let(:url) { "http://testtrack.dev/api/identifier" }

  subject { described_class.new(params) }

  before do
    stub_request(:post, url)
      .with(basic_auth: %w(dummy fakepassword))
      .to_return(status: 200, body: {
        visitor: {
          id: "fake_visitor_id_from_server",
          assignment_registry: { time: "clownin_around" },
          unsynced_splits: %w(car_size)
        }
      }.to_json)
  end

  it "doesn't hit the remote in test mode" do
    expect(subject.save).to eq true
    expect(WebMock).not_to have_requested(:post, url)
  end

  it "hits the server when enabled" do
    with_test_track_enabled { subject.save }
    expect(WebMock).to have_requested(:post, url).with(body: params.to_json)
  end

  it "constructs a Visitor object correctly" do
    with_test_track_enabled do
      subject.save
      expect(subject.visitor.id).to eq "fake_visitor_id_from_server"
      expect(subject.visitor.assignment_registry).to eq("time" => "clownin_around")
      expect(subject.visitor.unsynced_splits).to eq(%w(car_size))
    end
  end

  it "ignores extra data in the response body" do
    allow(subject).to receive(:fake_save_response_attributes).and_return(
      visitor: { id: "fake_visitor_id", assignment_registry: {}, unsynced_splits: %w(some_split), other_data: %w(a b c d) }
    )

    subject.save
    expect(subject.visitor.id).to eq "fake_visitor_id"
    expect(subject.visitor.assignment_registry).to eq({})
    expect(subject.visitor.unsynced_splits).to eq(%w(some_split))
  end

  describe "#visitor" do
    it "raises if the model hasn't been saved yet" do
      expect { subject.visitor }
        .to raise_error("Visitor data unavailable until you save this identifier.")
    end
  end
end
