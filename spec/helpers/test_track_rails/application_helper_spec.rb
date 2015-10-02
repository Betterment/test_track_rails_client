require 'rails_helper'

RSpec.describe TestTrackRails::ApplicationHelper do
  describe "#test_track_setup_tag" do
    let(:split_registry_url) { "http://dummy:fakepassword@testtrack.dev/api/split_registry" }
    let(:weightings) { { time: { hammertime: 0, millertime: 100 } } }

    let(:visitor_id) { SecureRandom.uuid }
    let(:assignment_registry_url) { "http://dummy:fakepassword@testtrack.dev/api/visitors/#{visitor_id}/assignment_registry" }
    let(:assignments) { { time: "hammertime" } }

    before do
      stub_request(:get, split_registry_url).to_return(body: weightings.to_json)
      stub_request(:get, assignment_registry_url).to_return(body: assignments.to_json)
    end

    it "returns a reasonable-looking script tag" do
      cookies[:tt_visitor_id] = visitor_id

      result = with_env(TEST_TRACK_ENABLED: 1) { helper.test_track_setup_tag }

      expect(result).to include("<script>")
      expect(result).to include("window.TEST_TRACK = {")
      expect(result).to include("host: 'http://dummy:fakepassword@testtrack.dev'")
      expect(result).to include("cookieDomain: '*.test.host',")
      expect(result).to include('registry: {"time":{"hammertime":0,"millertime":100}}')
      expect(result).to include('assignments: {"time":"hammertime"}')
    end
  end
end
