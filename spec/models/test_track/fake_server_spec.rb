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
end
