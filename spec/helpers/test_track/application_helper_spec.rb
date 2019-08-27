require 'rails_helper'

RSpec.describe TestTrack::ApplicationHelper do
  describe "#test_track_setup_tag" do
    let(:session) { instance_double(TestTrack::WebSession, state_hash: state_hash) }
    let(:state_hash) { { 'something' => 'or other!' } }

    before do
      # can't stub methods that don't exist, so define singleton methods emulating the TestTrack::Controller mixin
      session_var = session
      view.define_singleton_method(:test_track_session) do
        session_var
      end
    end

    it "returns a script tag with a base64-encoded variable encoded in it" do
      result = with_test_track_enabled { helper.test_track_setup_tag }

      expect(result).to include("<script>")

      base64_variable_match = result.match(/window.TT = '(.+)';/)

      expect(base64_variable_match).to be_present

      decoded_state_hash = JSON.parse(Base64.strict_decode64(base64_variable_match[1]))

      expect(decoded_state_hash).to eq state_hash
    end
  end
end
