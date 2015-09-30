require 'rails_helper'

module TestTrackRails
  RSpec.describe TestTrackRails do
    describe ".update_config" do
      it "yields an updater" do
        block_execution_count = 0
        TestTrackRails.update_config do |c|
          expect(c).to be_a(ConfigUpdater)
          block_execution_count += 1
        end
        expect(block_execution_count).to eq 1
      end
    end
  end
end
