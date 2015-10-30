require 'rails_helper'

RSpec.describe TestTrackRails::VaryConfig do
  let(:vary_config) do
    described_class.new(
      split_name: :button_size,
      assigned_variant: :one,
      split_registry: split_registry
    )
  end
  let(:split_registry) do
    {
      'button_size' => {
        'one' => 100,
        'two' => 0,
        'three' => 0,
        'four' => 0
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

  context "#initialize" do
    it "raises when given an unknown option" do
      expect do
        described_class.new(
          split_name: :button_size,
          assigned_variant: :one,
          split_registry: split_registry,
          one_of_these_things_is_not_like_the_other: "hint: its me!"
        )
      end.to raise_error ArgumentError
    end

    it "raises when missing a required option" do
      expect do
        described_class.new(
          assigned_variant: :one,
          split_registry: split_registry
        )
      end.to raise_error ArgumentError
    end
  end

  context "#run" do
    let(:one_two_variation) do
      vary_config.when(:one) { "hello!" }
      vary_config.default :two, &:noop
      vary_config.send :run
    end

    it "tells errbit if all variants aren't covered" do
      expect(one_two_variation).to eq "hello!"
      expect(vary_config).to have_received(:errbit).with("three and four are missing")
    end
  end

  context "#when" do
    it "supports multiple variants" do
      vary_config.when :one, :two, :three, &:noop

      expect(vary_config.send(:branches).size).to eq 3
      expect(vary_config.send(:branches).keys).to eq %w(one two three)
    end

    it "tells errbit if variant not in registry" do
      vary_config.when :this_does_not_exist, &:noop

      expect(vary_config).to have_received(:errbit).with('"this_does_not_exist" is not in options ["one", "two", "three", "four"]')
    end

    it "tells errbit about only invalid variant(s)" do
      vary_config.when :this_does_not_exist, :two, :three, :and_neither_does_this_one, &:noop

      expect(vary_config).to have_received(:errbit).with('"this_does_not_exist" is not in options ["one", "two", "three", "four"]')
      expect(vary_config).to have_received(:errbit).with('"and_neither_does_this_one" is not in options ["one", "two", "three", "four"]')
    end
  end

  context "#default" do
    it "accepts a block" do
      vary_config.when :one do
        puts "hello"
      end

      expect(vary_config.send(:branches).size).to eq 1
      expect(vary_config.send(:branches)['one']).to be_a Proc
      expect(vary_config.send(:branches)[:one]).to be_a Proc
    end

    it "tells errbit if variant not in registry" do
      vary_config.default :this_does_not_exist, &:noop

      expect(vary_config).to have_received(:errbit)
    end
  end
end
