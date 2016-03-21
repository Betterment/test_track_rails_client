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
      expect(subject.assignments.first).to be_a(TestTrack::Fake::Visitor::Assignment)
    end
  end

  describe '.reset!' do
    it 'resets the visitor instance and sets the seed' do
      old_visitor = TestTrack::Fake::Visitor.instance

      TestTrack::FakeServer.reset!(100)

      expect(old_visitor).not_to eq TestTrack::Fake::Visitor.instance
      expect(TestTrack::Fake::Visitor.instance.id).to eq 100
      expect(TestTrack::FakeServer.seed).to eq 100
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
      it 'raises as an error to reset the FakeServer' do
        expect(subject.instance_variable_get(:@seed)).to eq nil

        expect{ subject.seed }.to raise_error('TestTrack::FakeServer seed not set. Call TestTrack::FakeServer.reset!(seed) to set seed.')
      end
    end
  end
end
