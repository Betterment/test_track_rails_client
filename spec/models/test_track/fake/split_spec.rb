require 'rails_helper'

RSpec.describe TestTrack::Fake::Split do
  subject { Class.new(described_class).instance }

  context 'when splits exist' do
    describe '#split_details' do
      it 'returns a hash of split details for a split' do
        expect(subject.split_details["name"]).to eq "banner_color"
      end
    end
  end
end
