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

    it "wraps custom singleton client in SafeWrapper" do
      fake_client = double
      fake_client_class = double(instance: fake_client)
      stub_const('FakeClient', fake_client_class)
      TestTrack.analytics_class_name = 'FakeClient'

      expect(TestTrack.analytics.class).to eq TestTrack::Analytics::SafeWrapper
      expect(TestTrack.analytics.underlying).to eq fake_client
    ensure
      TestTrack.instance_variable_set(:@analytics_class_name, nil)
    end

    it "wraps custom argless-instantiable client in SafeWrapper" do
      fake_client = double
      fake_client_class = double(new: fake_client)
      stub_const('FakeClient', fake_client_class)
      TestTrack.analytics_class_name = 'FakeClient'

      expect(TestTrack.analytics.class).to eq TestTrack::Analytics::SafeWrapper
      expect(TestTrack.analytics.underlying).to eq fake_client
    ensure
      TestTrack.instance_variable_set(:@analytics_class_name, nil)
    end
  end

  describe "misconfguration_notifier" do
    it "wraps a singleton custom notifier in Wrapper without memoizing" do
      fake_notifier = double
      fake_notifier_class = double(instance: fake_notifier)
      stub_const('FakeNotifier', fake_notifier_class)
      TestTrack.misconfiguration_notifier_class_name = 'FakeNotifier'

      expect(TestTrack.misconfiguration_notifier).to be_instance_of(TestTrack::MisconfigurationNotifier::Wrapper)
      expect(TestTrack.misconfiguration_notifier.underlying).to eq fake_notifier
    ensure
      TestTrack.instance_variable_set(:@misconfiguration_notifier_class_name, nil)
    end

    it "wraps a argless-instantiable custom notifier in Wrapper without memoizing" do
      fake_notifier = double
      fake_notifier_class = double(new: fake_notifier)
      stub_const('FakeNotifier', fake_notifier_class)
      TestTrack.misconfiguration_notifier_class_name = 'FakeNotifier'

      expect(TestTrack.misconfiguration_notifier).to be_instance_of(TestTrack::MisconfigurationNotifier::Wrapper)
      expect(TestTrack.misconfiguration_notifier.underlying).to eq fake_notifier
    ensure
      TestTrack.instance_variable_set(:@misconfiguration_notifier_class_name, nil)
    end

    it "returns a new instance each time" do
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

  describe '#build_timestamp' do
    around do |example|
      Timecop.freeze(Time.zone.parse('2020-02-01')) do
        TestTrack.remove_instance_variable(:@build_timestamp) if TestTrack.instance_variable_defined?(:@build_timestamp)
        example.run
      end
    end

    context 'in a test environment' do
      it 'assigns build_timestamp to now' do
        expect(TestTrack.build_timestamp).to eq('2020-02-01T00:00:00Z')
      end
    end

    context 'in a development environment' do
      it 'assigns build_timestamp to now' do
        with_rails_env('development') do
          expect(TestTrack.build_timestamp).to eq('2020-02-01T00:00:00Z')
        end
      end
    end

    context 'in non test or development environment' do
      let(:file_readable) { true }

      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with('testtrack/build_timestamp').and_return(file_readable)
        allow(File).to receive(:read).and_call_original
        allow(File).to receive(:read).with('testtrack/build_timestamp').and_return("2020-02-21T00:00:00Z\n")
      end

      context 'with an existing build_timestamp file' do
        it 'assigns build_timestamp to file\'s contents' do
          with_rails_env('production') do
            expect(TestTrack.build_timestamp).to eq('2020-02-21T00:00:00Z')
          end
        end
      end

      context 'without a build_timestamp file' do
        let(:file_readable) { false }

        it 'raises an error' do
          with_rails_env('production') do
            expect { TestTrack.build_timestamp }
              .to raise_error(
                RuntimeError,
                'TestTrack failed to load the required build timestamp. ' \
                  'Ensure `test_track:generate_build_timestamp` task is run in `assets:precompile` and the build timestamp file is present.'
              )
          end
        end
      end

      context 'when the timestamp is not a valid ISO format' do
        before do
          allow(File).to receive(:read).and_return('2020-02-01 12:00:00 -0500')
        end

        it 'raises an error' do
          with_rails_env('production') do
            error_message = "./testtrack/build_timestamp is not a valid ISO 8601 timestamp, got '2020-02-01 12:00:00 -0500'"

            expect { TestTrack.build_timestamp }
              .to raise_error(RuntimeError, error_message)
          end
        end
      end

      context 'when the timestamp does not have seconds' do
        before do
          allow(File).to receive(:read).and_return('2020-02-01T12:00Z')
        end

        it 'raises an error' do
          with_rails_env('production') do
            expect { TestTrack.build_timestamp }
              .to raise_error(RuntimeError, "./testtrack/build_timestamp is not a valid ISO 8601 timestamp, got '2020-02-01T12:00Z'")
          end
        end
      end

      context 'when the timestamp file is empty' do
        before do
          allow(File).to receive(:read).and_return('')
        end

        it 'raises an error' do
          with_rails_env('production') do
            expect { TestTrack.build_timestamp }
              .to raise_error(
                RuntimeError,
                'TestTrack failed to load the required build timestamp. ' \
                  'Ensure `test_track:generate_build_timestamp` task is run in `assets:precompile` and the build timestamp file is present.'
              )
          end
        end
      end
    end

    context 'when set via full assets:precompile command' do
      around do |example|
        Dir.chdir('spec/dummy') do
          File.delete('testtrack/build_timestamp') if File.exist?('testtrack/build_timestamp')
          example.run
        end
      end

      let(:assets_precompile_success) do
        system({ 'RAILS_ENV' => 'production' }, 'bundle exec rake assets:precompile')
      end

      let(:assets_clobber_success) do
        system({ 'RAILS_ENV' => 'production' }, 'bundle exec rake assets:clobber')
      end

      it 'does not raise an error' do
        expect { assets_precompile_success }
          .to change { File.exist?('testtrack/build_timestamp') }
          .from(false).to(true)
        expect(assets_precompile_success).to eq true

        expect { assets_clobber_success }
          .to change { File.exist?('testtrack/build_timestamp') }
          .from(true).to(false)
        expect(assets_clobber_success).to eq true
      end
    end
  end
end
