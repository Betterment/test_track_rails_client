require 'rails_helper'

RSpec.describe TestTrack::FakeServer do
  subject { Class.new described_class }

  describe '.split_registry' do
    it 'returns an array of fake splits' do
      expect(subject.split_registry).to be_an(Array)
      expect(subject.split_registry.first).to be_a(TestTrack::Fake::SplitRegistry::Split)
    end
  end

  describe '.visitor' do
    it 'returns a fake visitor' do
      expect(subject.visitor).to be_a(TestTrack::Fake::Visitor)
    end
  end

  describe '.assignments' do
    it 'returns an array of fake splits' do
      expect(subject.assignments).to be_an(Array)
      expect(subject.assignments.first).to be_a(TestTrack::Fake::SplitRegistry::Split)
    end
  end

  describe '.reset!' do
    context 'with no argument' do
      it 'sets a random seed' do
        expect(subject.instance_variable_get(:@seed)).to eq nil

        subject.reset!

        expect(subject.instance_variable_get(:@seed)).not_to eq nil
      end
    end

    context 'with an argument' do
      it 'sets the seed to the argument' do
        expect(subject.instance_variable_get(:@seed)).to eq nil

        subject.reset!(100)

        expect(subject.instance_variable_get(:@seed)).to eq 100
      end
    end
  end

  describe '.seed' do
    context 'with a seed set' do
      it 'returns the seed' do
        subject.instance_variable_set(:@seed, 10)

        expect(subject.seed).to eq 10
      end
    end

    context 'with no seed set' do
      it 'sets and returns a random seed' do
        expect(subject.instance_variable_get(:@seed)).to eq nil

        expect(subject.seed).not_to eq nil

        expect(subject.instance_variable_get(:@seed)).not_to eq nil
      end
    end
  end
end
