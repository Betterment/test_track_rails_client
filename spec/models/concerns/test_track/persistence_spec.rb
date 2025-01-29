require 'rails_helper'

RSpec.describe TestTrack::Persistence do
  let(:resource) do
    Class.new do
      include TestTrack::Resource
      include TestTrack::Persistence

      attribute :name
      attribute :saved, default: false

      validates :name, presence: true

      private

      def persist!
        self.saved = true
      end
    end
  end

  before do
    stub_const('FakeResource', resource)
  end

  describe '#save' do
    subject { resource.new(name: 'foo') }

    it 'saves' do
      expect(subject).to be_valid
      expect(subject.save).to be(true)
      expect(subject.saved).to be(true)
    end

    it 'does not save an invalid resource' do
      subject.name = ''
      expect(subject).not_to be_valid
      expect(subject.save).to be(false)
      expect(subject.saved).to be(false)
    end

    it 'handles server errors' do
      allow(subject).to receive(:persist!).and_raise(Faraday::UnprocessableEntityError, 'kaboom')

      expect(subject).to be_valid
      expect(subject.save).to be(false)
      expect(subject.saved).to be(false)
      expect(subject.errors[:base]).to include('The HTTP request failed with a 422 status code')
    end
  end

  describe '#save!' do
    let(:subject) { resource.new(name: 'foo') }

    it 'returns true when the resource is successfully saved' do
      expect(subject.save!).to be(true)
    end

    it 'raises ActiveModel::ValidationError the resource is not saved' do
      subject.name = ''
      expect { subject.save! }.to raise_error(ActiveModel::ValidationError)
    end

    it 'converts server errors to validation errors' do
      allow(subject).to receive(:persist!).and_raise(Faraday::UnprocessableEntityError, 'kaboom')

      expect { subject.save! }.to raise_error(ActiveModel::ValidationError)
      expect(subject.errors[:base]).to include('The HTTP request failed with a 422 status code')
    end
  end

  describe '.create!' do
    it 'returns a new instance when the resource is successfully saved' do
      expect(resource.create!(name: 'Foo')).to be_a(resource)
    end

    it 'raises ActiveModel::ValidationError the resource is not saved' do
      expect { resource.create!(name: '') }.to raise_error(ActiveModel::ValidationError)
    end
  end
end
