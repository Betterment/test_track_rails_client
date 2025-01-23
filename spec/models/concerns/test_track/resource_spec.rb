require 'rails_helper'

RSpec.describe TestTrack::Resource do
  subject do
    Class.new do
      include TestTrack::Resource

      attribute :name
    end
  end

  it 'allows attributes to be defined' do
    instance = subject.new(name: 'foo')
    expect(instance.name).to eq('foo')
  end

  it 'does not complain about unknown attributes' do
    expect { subject.new(unknown: 'foo') }.not_to raise_error
  end
end
