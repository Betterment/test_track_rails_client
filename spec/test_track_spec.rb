require 'rails_helper'

RSpec.describe TestTrack do
  describe ".update_config" do
    it "yields an updater" do
      block_execution_count = 0
      TestTrack.update_config do |c|
        expect(c).to be_a(TestTrack::ConfigUpdater)
        block_execution_count += 1
      end
      expect(block_execution_count).to eq 1
    end
  end

  describe ".enabled?" do
    around do |example|
      original_enabled = TestTrack.instance_variable_get("@enabled")
      example.run
      TestTrack.enabled_override = original_enabled
    end

    context "test environment" do
      it "is not enabled by default" do
        expect(TestTrack).not_to be_enabled
      end

      it "can be enabled" do
        TestTrack.enabled_override = true
        expect(TestTrack).to be_enabled
      end
    end

    context "non-test environment" do
      around do |example|
        with_rails_env("development") { example.run }
      end

      it "is enabled by default" do
        expect(TestTrack).to be_enabled
      end

      it "can be disabled" do
        TestTrack.enabled_override = false
        expect(TestTrack).not_to be_enabled
      end
    end
  end

  describe "login_callback" do
    it "noops by default" do
      expect(TestTrack.login_callback.call(test_track_visitor_id: 1)).to be_nil
    end

    it "is configurable" do
      begin
        TestTrack.login_callback = ->(_){ 'custom callback' }
        expect(TestTrack.login_callback.call(test_track_visitor_id: 1)).to eq 'custom callback'
      ensure
        TestTrack.login_callback = nil
      end
    end
  end

  describe "signup_callback" do
    it "noops by default" do
      expect(TestTrack.signup_callback.call(test_track_visitor_id: 1)).to be_nil
    end

    it "is configurable" do
      begin
        TestTrack.signup_callback = ->(_){ 'custom callback' }
        expect(TestTrack.signup_callback.call(test_track_visitor_id: 1)).to eq 'custom callback'
      ensure
        TestTrack.signup_callback = nil
      end
    end
  end

  describe "analytics" do
    it "wraps default client in SafeWrapper" do
      expect(TestTrack.analytics.class).to eq TestTrack::Analytics::SafeWrapper
      expect(TestTrack.analytics.underlying.class).to eq TestTrack::Analytics::MixpanelClient
    end

    it "wraps custom client in SafeWrapper" do
      begin
        default_client = TestTrack.analytics
        fake_client = double
        TestTrack.analytics = fake_client

        expect(TestTrack.analytics.class).to eq TestTrack::Analytics::SafeWrapper
        expect(TestTrack.analytics.underlying).to eq fake_client
      ensure
        TestTrack.analytics = default_client
      end
    end
  end
end
