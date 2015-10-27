require 'rails_helper'

RSpec.describe TestTrackRails::VaryConfig do
  let(:vary_config) { described_class.new(:button_size, :one, split_registry) }
  let(:split_registry) do
    {
      'button_size' => {
        'one' => 100,
        'two' => 0,
        'three' => 0
      },
      'time' => {
        'hammertime' => 50,
        'clobberin_time' => 50
      }
    }
  end
  let(:noop) { -> {} }

  before do
    allow(vary_config).to receive(:errbit).and_call_original
  end

  it "isn't defaulted by default" do
    expect(vary_config.defaulted?).to be_falsey
  end

  context "#when" do
    it "supports multiple variant_names" do
      vary_config.when :one, :two, :three, &:noop

      expect(vary_config.branches.size).to eq 3
      expect(vary_config.branches.keys).to eq %w(one two three)
    end

    it "tells errbit if variant_name not in registry" do
      vary_config.when :this_does_not_exist, &:noop

      expect(vary_config).to have_received(:errbit)
    end

    it "tells errbit about only invalid variant_name(s)" do
      vary_config.when :this_does_not_exist, :two, :three, :and_neither_does_this_one, &:noop

      expect(vary_config).to have_received(:errbit).exactly(:twice)
    end
  end

  context "#default" do
    it "accepts a block" do
      vary_config.when :one do
        puts "hello"
      end

      expect(vary_config.branches.size).to eq 1
      expect(vary_config.branches['one']).to be_a Proc
      expect(vary_config.branches[:one]).to be_a Proc
    end

    it "tells errbit if variant_name not in registry" do
      vary_config.default :this_does_not_exist, &:noop

      expect(vary_config).to have_received(:errbit)
    end
  end
end
