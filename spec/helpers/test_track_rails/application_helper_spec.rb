require 'rails_helper'

RSpec.describe TestTrackRails::ApplicationHelper do
  describe "#test_track_setup_tag" do
    before do
      # can't stub methods that don't exist, so define singleton methods emulating the TestTrackableController mixin
      def view.tt_cookie_domain
        '.example.com'
      end

      def view.tt_split_registry
        { time: { hammertime: 0, millertime: 100 } }
      end

      def view.tt_assignment_registry
        { time: "hammertime" }
      end
    end

    it "returns a reasonable-looking script tag" do
      result = with_env(TEST_TRACK_ENABLED: 1) { helper.test_track_setup_tag }

      expect(result).to include("<script>")
      expect(result).to include("window.TEST_TRACK = {")
      expect(result).to include("url: 'http://testtrack.dev',")
      expect(result).to include("cookieDomain: '.example.com',")
      expect(result).to include('registry: {"time":{"hammertime":0,"millertime":100}},')
      expect(result).to include('assignments: {"time":"hammertime"}')
    end
  end
end
