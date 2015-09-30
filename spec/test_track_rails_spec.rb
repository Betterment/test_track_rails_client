require 'rails_helper'

module TestTrackRails
  RSpec.describe TestTrackRails do
    describe ".update_config" do
      it "yields an updater" do
        TestTrackRails.update_config do |c|
          expect(c).to be_a(ConfigUpdater)
        end
      end
    end
  end
end
