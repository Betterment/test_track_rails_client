require 'rails_helper'

RSpec.describe TestTrack::Fake::SplitRegistry do
  subject { Class.new(described_class).instance }

  shared_examples_for 'a schema' do |path|
    before do
      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:exist?).with(Rails.root.join(path).to_s).and_return(true)
    end

    describe '#to_h' do
      it 'returns a hash containing all splits with deterministic weights' do
        expect(subject.to_h).to eq(
          {
            splits: {
              buy_one_get_one_promotion_enabled: {
                weights: {
                  false: 100, # rubocop:disable Lint/BooleanSymbol
                  true: 0 # rubocop:disable Lint/BooleanSymbol
                },
                feature_gate: true
              },
              banner_color: {
                weights: {
                  blue: 100,
                  white: 0,
                  red: 0
                },
                feature_gate: false
              },
              decided_split: {
                weights: {
                  control: 0,
                  treatment: 100
                },
                feature_gate: false
              }
            },
            experience_sampling_weight: 1
          }.with_indifferent_access
        )
      end
    end

    describe '#splits' do
      it 'returns an array of splits with deterministic weights' do
        expect(subject.splits).to match_array [
          TestTrack::Fake::SplitRegistry::Split.new('banner_color', 'blue' => 100, 'red' => 0, 'white' => 0),
          TestTrack::Fake::SplitRegistry::Split.new('buy_one_get_one_promotion_enabled', 'false' => 100, 'true' => 0),
          TestTrack::Fake::SplitRegistry::Split.new('decided_split', 'control' => 0, 'treatment' => 100)
        ]
      end
    end
  end

  context 'when testtrack/schema.json exists' do
    include_examples 'a schema', 'testtrack/schema.json'
  end

  context 'when testtrack/schema.yml exists' do
    include_examples 'a schema', 'testtrack/schema.yml'
  end

  context "when db/test_track_schema.yml exists" do
    include_examples 'a schema', 'db/test_track_schema.yml'
  end

  context "when no schema is found" do
    before do
      allow(File).to receive(:exist?).and_return(false)
    end

    describe '#to_h' do
      it 'returns an empty split registry' do
        expect(subject.to_h).to eq('splits' => {}, 'experience_sampling_weight' => 1)
      end
    end

    describe '#splits' do
      it 'returns an empty array' do
        expect(subject.splits).to eq([])
      end
    end
  end
end
