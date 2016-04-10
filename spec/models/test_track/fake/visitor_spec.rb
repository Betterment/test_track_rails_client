require 'rails_helper'

RSpec.describe TestTrack::Fake::Visitor do
  subject { Class.new(described_class).instance }

  describe '.reset!' do
    it 'resets the instance' do
      TestTrack::Fake::Visitor.instance

      allow(TestTrack::FakeServer).to receive(:seed).and_return(5)

      TestTrack::Fake::Visitor.reset!

      expect(TestTrack::Fake::Visitor.instance.id).to eq 5
    end
  end

  context 'when splits exist' do
    before do
      TestTrack::FakeServer.reset!(1)
    end

    describe '#assignments' do
      it 'returns an array of assignments' do
        expect(subject.assignments).to match_array [
          TestTrack::Fake::Visitor::Assignment.new('buy_one_get_one_promotion_enabled', 'false', false),
          TestTrack::Fake::Visitor::Assignment.new('banner_color', 'white', false)
        ]
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
  end
end
