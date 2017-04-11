require 'rails_helper'

RSpec.describe TestTrack::Remote::SplitDetail do
  before do
    stub_request(:get, url)
      .with(basic_auth: %w(dummy fakepassword))
      .to_return(status: 200, body: {
        name: "fake_split_name_from_server",
        hypothesis: "hypothesis from a real server",
        assignment_criteria: "criteria about real not fake users",
        description: "description about a very real test",
        owner: "best owner ever",
        location: "the homepage above the fold",
        platform: "mobile",
        variant_details: [
          {
            name: "variant detail a",
            description: "blue banner on homepage"
          },
          {
            name: "variant detail b",
            description: "no banner on homepage"
          }
        ]
      }.to_json)
  end

  describe ".find" do
    let(:url) { "http://testtrack.dev/api/v1/split_details/fake_split_name_from_server" }
    subject { described_class.find("fake_split_name_from_server") }

    it "loads split details with fake instance attributes" do
      expect(subject.name).to eq("fake_split_name_from_server")
      expect(subject.hypothesis).to eq("fake hypothesis")
      expect(subject.assignment_criteria).to eq("fake criteria for everyone")
      expect(subject.description).to eq("fake but still good description")
      expect(subject.owner).to eq("fake owner")
      expect(subject.location).to eq("fake activity")
      expect(subject.platform).to eq("mobile")

      expect(subject.variant_details.size).to eq 2
      expect(subject.variant_details.first[:name]).to eq("fake first variant detail")
      expect(subject.variant_details.first[:description]).to eq("There are FAQ links in a sidebar")
      expect(subject.variant_details.last[:name]).to eq("fake second variant detail")
      expect(subject.variant_details.last[:description]).to eq("There are FAQ links in the default footer")
    end

    it "fetches attributes from the test track server when enabled" do
      with_test_track_enabled do
        expect(subject.name).to eq("fake_split_name_from_server")
        expect(subject.hypothesis).to eq("hypothesis from a real server")
        expect(subject.assignment_criteria).to eq("criteria about real not fake users")
        expect(subject.description).to eq("description about a very real test")
        expect(subject.owner).to eq("best owner ever")
        expect(subject.location).to eq("the homepage above the fold")
        expect(subject.platform).to eq("mobile")

        expect(subject.variant_details.size).to eq 2
        expect(subject.variant_details.first[:name]).to eq("variant detail a")
        expect(subject.variant_details.first[:description]).to eq("blue banner on homepage")
        expect(subject.variant_details.last[:name]).to eq("variant detail b")
        expect(subject.variant_details.last[:description]).to eq("no banner on homepage")
      end
    end
  end

  describe ".from_name" do
    subject { described_class.from_name("clown_id") }
    let(:url) { "http://testtrack.dev/api/v1/split_details/clown_id" }

    it "loads split details with instance attributes" do
      expect(subject.name).to eq("clown_id")
    end

    it "fetches attributes from the test track server when enabled" do
      with_test_track_enabled do
        expect(subject.name).to eq("fake_split_name_from_server")
      end
    end
  end
end
