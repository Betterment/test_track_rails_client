require 'rails_helper'

RSpec.describe TestTrack::Fake::SplitDetail do
  subject { Class.new(described_class).instance }

  context 'when splits exist' do
    describe '#details' do
      it 'returns a hash of split details for a split' do
        expect(subject.details[:name]).to eq "banner_color"
        expect(subject.details[:owner]).to eq "mobile team"
        expect(subject.details[:platform]).to eq "mobile"
        expect(subject.details[:location]).to eq "home screen"
        expect(subject.details[:assignment_criteria]).to eq "user has mobile app"
        expect(subject.details[:hypothesis]).to eq "user will interact more with blue banner"
      end
    end
  end
end
