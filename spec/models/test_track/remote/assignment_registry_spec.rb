require 'rails_helper'

RSpec.describe TestTrack::Remote::AssignmentRegistry do
  describe ".for_visitor" do
    subject { described_class.for_visitor("visitor_id") }
    let(:url) { "http://dummy:fakepassword@testtrack.dev/api/visitors/visitor_id/assignment_registry" }

    before do
      stub_request(:get, url).to_return(status: 200, body: { remote_split: :variant1 }.to_json)
    end

    it "blows up when passed a blank visitor_id" do
      expect { described_class.for_visitor("") }
        .to raise_error("must provide a visitor_id")
    end

    it "instantiates a AssignmentRegistry with fake instance attributes" do
      expect(subject.attributes).to eq("time" => "hammertime")
    end

    it "it fetches attributes from the test track server when enabled" do
      with_env(TEST_TRACK_ENABLED: 1) do
        expect(subject.attributes).to eq("remote_split" => "variant1")
      end
    end
  end
end
