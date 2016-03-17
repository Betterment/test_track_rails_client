require 'rails_helper'

RSpec.describe TestTrack::Fake::Visitor do
  subject { Class.new(described_class).instance }

  describe '#unsynced_splits' do
    it 'returns an empty array' do
      expect(subject.unsynced_splits).to eq []
    end
  end

  context 'when splits exist' do
    describe '#assignments' do
      it 'returns an array of splits' do
        expect(subject.assignments).to match_array [
          TestTrack::Fake::SplitRegistry::Split.new('buy_one_get_one_promotion_enabled', 'false' => 50, 'true' => 50),
          TestTrack::Fake::SplitRegistry::Split.new('banner_color', 'blue' => 34, 'white' => 33, 'red' => 33)
        ]
      end
    end

    describe '#assignment_registry' do
      before do
        allow_any_instance_of(TestTrack::Fake::SplitRegistry::Split).to receive(:sample_variant) { |split| split.registry.keys.first }
      end

      it 'returns a hash of splits and assignments' do
        expect(subject.assignment_registry).to eq(buy_one_get_one_promotion_enabled: :false, banner_color: :blue)
      end
    end
  end

  context 'when splits do not exist' do
    before do
      allow(TestTrack::Fake::SplitRegistry.instance).to receive(:splits).and_return([])
    end

    describe '#assignments' do
      it 'returns an empty array' do
        expect(subject.assignments).to eq []
      end
    end

    describe '#assignment_registry' do
      it 'returns an empty hash' do
        expect(subject.assignment_registry).to eq({})
      end
    end
  end
end
