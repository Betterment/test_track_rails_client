require 'rails_helper'

RSpec.describe TestTrack::Remote::SplitDetail do
  before do
    stub_request(:get, url)
      .with(basic_auth: %w(dummy fakepassword))
      .to_return(status: 200, body: {
        split_name: "fake_split_name_from_server",
        hypothesis: "hypothesis",
        assignment_criteria: "criteria",
        description: "description",
        owner: "retail",
        location: "activity",
        platform: "mobile"
      }.to_json)
  end

  describe ".find" do
    let(:url) { "http://testtrack.dev/api/v1/split_details/fake_split_name_from_server" }
    subject { described_class.find("fake_split_name_from_server") }

    it "loads split details with fake instance attributes" do
      expect(subject.split_name).to eq("fake_visitor_id")
      expect(subject.hypothesis).to eq("fake_hypothesis")
      expect(subject.assignment_criteria).to eq("fake_criteria")
      expect(subject.description).to eq("fake_description")
      expect(subject.owner).to eq("fake_retail")
      expect(subject.location).to eq("fake_activity")
      expect(subject.platform).to eq("fake_mobile")
    end

    it "fetches attributes from the test track server when enabled" do
      with_test_track_enabled do
        expect(subject.split_name).to eq("fake_split_name_from_server")
      end
    end
  end

  describe ".from_name" do
    subject { described_class.from_name("clown_id") }
    let(:url) { "http://testtrack.dev/api/v1/split_details/clown_id" }

    it "raises when given a blank identifier_value" do
      expect { TestTrack::Remote::SplitDetail.from_name("") }
        .to raise_error("must provide a name")
    end

    it "loads split details with instance attributes" do
      expect(subject.split_name).to eq("fake_visitor_id")
    end

    it "fetches attributes from the test track server when enabled" do
      with_test_track_enabled do
        expect(subject.split_name).to eq("fake_split_name_from_server")
      end
    end
  end
end
