require 'rails_helper'

RSpec.describe TestTrack::Remote::Visitor do
  describe ".find" do
    let(:url) { "http://testtrack.dev/api/v1/visitors/fake_visitor_id_from_server" }

    subject { described_class.find("fake_visitor_id_from_server") }

    before do
      stub_request(:get, url)
        .with(basic_auth: %w(dummy fakepassword))
        .to_return(status: 200, body: {
          id: "fake_visitor_id_from_server",
          assignment_registry: { time: "clownin_around" },
          unsynced_splits: %w(time)
        }.to_json)
    end

    it "instantiates a Visitor with fake instance attributes" do
      expect(subject.id).to eq("fake_visitor_id")
      expect(subject.assignment_registry).to eq("time" => 'hammertime')
      expect(subject.unsynced_splits).to eq([])
    end

    it "it fetches attributes from the test track server when enabled" do
      with_test_track_enabled do
        expect(subject.id).to eq("fake_visitor_id_from_server")
        expect(subject.assignment_registry).to eq("time" => "clownin_around")
        expect(subject.unsynced_splits).to eq(%w(time))
      end
    end
  end
end
