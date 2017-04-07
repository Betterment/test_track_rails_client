require 'rails_helper'

RSpec.describe TestTrack::Fake::Split do
  subject { Class.new(described_class).instance }

  context 'when splits exist' do
    describe '#split_details' do
      it 'returns a hash of split details for a split' do
        expect(subject.split_details["name"]).to eq "banner_color"
        expect(subject.split_details["owner"]).to eq "mobile team"
        expect(subject.split_details["platform"]).to eq "mobile"
        expect(subject.split_details["location"]).to eq "home screen"
        expect(subject.split_details["assignment_criteria"]).to eq "user has mobile app"
        expect(subject.split_details["hypothesis"]).to eq "user will interact more with blue banner"
      end
    end
  end
end
