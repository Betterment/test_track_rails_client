require 'rails_helper'

RSpec.describe TestTrackRails::VaryConfig do
  let(:vary_config) { described_class.new(:blue_button, :true, split_registry) }
  let(:split_registry) do
    {
      'blue_button' => {
        'false' => 50,
        'true' => 50
      },
      'quagmire' => {
        'untenable' => 50,
        'manageable' => 50
      },
      'time' => {
        'hammertime' => 100,
        'clobberin_time' => 0
      }
    }
  end

  it "isn't defaulted by default" do
    expect(vary_config.defaulted?).to be_falsey
  end

  context "#when" do
    it "supports multiple variant_names" do
      vary_config.when :one, :two, :three do
        "one, two, or three"
      end

      expect(vary_config.branches.size).to eq 3
      expect(vary_config.branches.keys).to eq %w(one two three)
    end
  end

  context "#default" do
    it "accepts a block" do
      vary_config.when :hello do
        puts "hello"
      end
      expect(vary_config.branches['hello']).to be_a Proc
    end
  end
end
