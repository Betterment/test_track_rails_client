require 'rails_helper'

RSpec.describe TestTrackRails::VariantProcRunner do
  subject do
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
    allow(subject).to receive(:errbit).and_call_original
  end

  it "isn't defaulted by default" do
    expect(subject.defaulted?).to be_falsey
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
    it "tells errbit if all variants aren't covered" do
      subject.when(:one) { "hello!" }
      subject.default :two, &:noop

      expect(subject.send :run).to eq "hello!"
      expect(subject).to have_received(:errbit).with("three and four are missing")
    end
  end

  context "#when" do
    it "supports multiple variants" do
      subject.when :one, :two, :three, &:noop

      expect(subject.send(:variant_procs).size).to eq 3
      expect(subject.send(:variant_procs).keys).to eq %w(one two three)
    end

    it "tells errbit if variant not in registry" do
      subject.when :this_does_not_exist, &:noop

      expect(subject).to have_received(:errbit).with('"this_does_not_exist" is not in split_variants ["one", "two", "three", "four"]')
    end

    it "tells errbit about only invalid variant(s)" do
      subject.when :this_does_not_exist, :two, :three, :and_neither_does_this_one, &:noop

      expect(subject).to have_received(:errbit).with(
        '"this_does_not_exist" is not in split_variants ["one", "two", "three", "four"]')
      expect(subject).to have_received(:errbit).with(
        '"and_neither_does_this_one" is not in split_variants ["one", "two", "three", "four"]')
    end
  end

  context "#default" do
    it "accepts a block" do
      subject.when :one do
        puts "hello"
      end

      expect(subject.send(:variant_procs).size).to eq 1
      expect(subject.send(:variant_procs)['one']).to be_a Proc
      expect(subject.send(:variant_procs)[:one]).to be_nil
    end

    it "tells errbit if variant not in registry" do
      subject.default :this_does_not_exist, &:noop

      expect(subject).to have_received(:errbit)
    end
  end
end
