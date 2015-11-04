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
end
