require 'rails_helper'

RSpec.describe TestTrackRails::ApplicationHelper do
  describe "#test_track_setup_tag" do
    let(:url) { "http://dummy:fakepassword@testtrack.dev/api/split_registry" }

    let(:weightings) { { hammertime: 0, millertime: 100 } }

    before do
      stub_request(:get, url).to_return(body: weightings.to_json)
    end

    it "returns a reasonable-looking script tag" do
      result = with_env(TEST_TRACK_ENABLED: 1) { result = helper.test_track_setup_tag }

      expect(result).to include("<script>")
      expect(result).to include("window.TEST_TRACK = {")
      expect(result).to include("host: 'http://dummy:fakepassword@testtrack.dev'")
      expect(result).to include("cookieDomain: '*.test.host',")
      expect(result).to include('registry: {"hammertime":0,"millertime":100}')
    end
  end
end
