require 'rails_helper'

RSpec.describe TestTrack::Fake::SplitRegistry do
  subject { Class.new(described_class).instance }

  context 'when test_track_schema.yml exists' do
    describe '#to_h' do
      it 'returns a hash containing all splits with deterministic weights' do
        expect(subject.to_h).to eq(
          {
            splits: {
              buy_one_get_one_promotion_enabled: {
                weights: {
                  false: 100,
                  true: 0
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
              }
            },
            experience_sampling_weight: 1
          }.with_indifferent_access
        )
      end
    end

    describe '#splits' do
      it 'returns an array of splits with deterministic weights' do
        expect(subject.splits).to eq [
          TestTrack::Fake::SplitRegistry::Split.new('buy_one_get_one_promotion_enabled', 'false' => 100, 'true' => 0),
          TestTrack::Fake::SplitRegistry::Split.new('banner_color', 'blue' => 100, 'white' => 0, 'red' => 0)
        ]
      end
    end
  end

  context 'when test_track_schema.yml does not exist' do
    before do
      allow(YAML).to receive(:load_file).with(Rails.root.join('db', 'test_track_schema.yml')).and_return(nil)
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
