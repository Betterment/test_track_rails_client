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
      TestTrack.enabled = original_enabled
    end

    it "is always enabled in a non-test environment" do
      with_rails_env "development" do
        TestTrack.enabled = false
        expect(TestTrack).to be_enabled
      end
    end

    it "is not enabled by default in a test environment" do
      expect(TestTrack).not_to be_enabled
    end

    it "can be enabled in a test environment" do
      TestTrack.enabled = true
      expect(TestTrack).to be_enabled
    end
  end
end
