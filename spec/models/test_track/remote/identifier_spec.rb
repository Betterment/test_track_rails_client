require 'rails_helper'

RSpec.describe TestTrack::Remote::Identifier do
  let(:params) { { identifier_type: "clown_id", visitor_id: "fake_visitor_id", value: 1234 } }
  let(:url) { "http://testtrack.dev/api/v1/identifier" }

  subject { described_class.new(params) }

  before do
    stub_request(:post, url)
      .with(basic_auth: %w(dummy fakepassword))
      .to_return(status: 200, body: {
        visitor: {
          id: "fake_visitor_id_from_server",
          assignments: [
            { split_name: "time", variant: "clownin_around", unsynced: false, context: "context_a" },
            { split_name: "car_size", variant: "mini", unsynced: true, context: "context_b" }
          ],
          extra_data: %w(a b c d) # This should be ignored
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
      subject.visitor.assignment_registry["time"].tap do |assignment|
        expect(assignment.split_name).to eq "time"
        expect(assignment.variant).to eq "clownin_around"
        expect(assignment.context).to eq "context_a"
        expect(assignment.unsynced).to eq false
      end
      subject.visitor.assignment_registry["car_size"].tap do |assignment|
        expect(assignment.split_name).to eq "car_size"
        expect(assignment.variant).to eq "mini"
        expect(assignment.context).to eq "context_b"
        expect(assignment.unsynced).to eq true
      end
    end
  end

  describe "#visitor" do
    it "raises if the model hasn't been saved yet" do
      expect { subject.visitor }
        .to raise_error("Visitor data unavailable until you save this identifier.")
    end
  end
end
