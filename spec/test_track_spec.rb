require 'rails_helper'
require 'test_track_rails_client/rspec_helpers'

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

  describe "misconfguration_notifier" do
    it "wraps a custom notifier in Wrapper without memoizing" do
      begin
        fake_notifier = double
        fake_notifier_class = double(new: fake_notifier)
        stub_const('FakeNotifier', fake_notifier_class)
        TestTrack.misconfiguration_notifier_class_name = 'FakeNotifier'

        expect(TestTrack.misconfiguration_notifier).to be_instance_of(TestTrack::MisconfigurationNotifier::Wrapper)
        expect(TestTrack.misconfiguration_notifier.underlying).to eq fake_notifier
      ensure
        TestTrack.instance_variable_set(:@misconfiguration_notifier_class_name, nil)
      end
    end

    it "returns a new instance each time" do
      begin
        fake_notifier = double
        fake_notifier_class = double
        call_count = 0
        allow(fake_notifier_class).to receive(:new) do
          call_count += 1
          fake_notifier
        end
        stub_const('FakeNotifier', fake_notifier_class)
        TestTrack.misconfiguration_notifier_class_name = 'FakeNotifier'

        expect {
          3.times { TestTrack.misconfiguration_notifier }
        }.to change { call_count }.by(3)
      ensure
        TestTrack.instance_variable_set(:@misconfiguration_notifier_class_name, nil)
      end
    end

    context "when Airbrake is defined" do
      it "defaults Airbrake notifier without memoizing" do
        expect(TestTrack.misconfiguration_notifier.underlying.class).to eq TestTrack::MisconfigurationNotifier::Null
        stub_const("Airbrake", double("Airbrake"))
        expect(TestTrack.misconfiguration_notifier.underlying.class).to eq TestTrack::MisconfigurationNotifier::Airbrake
      end
    end

    it "defaults to null notifier" do
      expect(TestTrack.misconfiguration_notifier.class).to eq TestTrack::MisconfigurationNotifier::Wrapper
      expect(TestTrack.misconfiguration_notifier.underlying.class).to eq TestTrack::MisconfigurationNotifier::Null
    end
  end

  describe ".app_ab" do
    around do |example|
      original_app_name = TestTrack.instance_variable_get("@app_name")
      example.run
      TestTrack.app_name = original_app_name
    end

    context "when app_name is specified" do
      before { TestTrack.app_name = 'test_track_spec' }

      context "when the ApplicationIdentity is assigned to the feature" do
        before do
          stub_test_track_assignments(dummy_feature: 'true')
        end
        it "returns true" do
          expect(TestTrack.app_ab(:dummy_feature, context: 'test_context')).to eq true
        end
      end

      context "when the ApplicationIdentity is not assigned to the feature" do
        before do
          stub_test_track_assignments(dummy_feature: 'false')
        end

        it "returns false" do
          expect(TestTrack.app_ab(:dummy_feature, context: 'test_context')).to eq false
        end
      end
    end

    context "when app_name is not specified" do
      before do
        TestTrack.app_name = nil
      end

      it "raises an error" do
        expect { TestTrack.app_ab(:dummy_feature, context: 'test_context') }
          .to raise_error("must configure TestTrack.app_name on application initialization")
      end
    end
  end
end
