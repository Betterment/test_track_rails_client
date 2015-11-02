require 'rails_helper'

RSpec.describe TestTrackRails::ApplicationHelper do
  describe "#test_track_setup_tag" do
    let(:session) { instance_double(TestTrackRails::Session, state_hash: state_hash) }
    let(:state_hash) { { 'something' => 'or other!' } }

    before do
      # can't stub methods that don't exist, so define singleton methods emulating the TestTrackableController mixin
      session_var = session
      view.define_singleton_method(:test_track_session) do
        session_var
      end
    end

    it "returns a script tag with a base64-encoded variable encoded in it" do
      result = with_env(TEST_TRACK_ENABLED: 1) { helper.test_track_setup_tag }

      expect(result).to include('<div class="_tt" style="visibility:hidden;width:0;height:0;">')
      expect(result).to include("<script>")

      base64_variable_match = result.match(/window.TT = '(.+)';/)

      expect(base64_variable_match).to be_present

      decoded_state_hash = JSON.load(Base64.strict_decode64(base64_variable_match[1]))

      expect(decoded_state_hash).to eq state_hash
    end
  end
end
