require 'rails_helper'

RSpec.describe TestTrack::FakeSplitCollection do
  subject { described_class.clone }

  describe '.to_h' do
    context 'when test_track_schema.yml exists' do
      it 'returns a hash containing all splits' do
        expect(subject.to_h).to eq(
          {
            buy_one_get_one_promotion_enabled: {
              false: 50,
              true: 50
            },
            banner_color: {
              blue: 34,
              white: 33,
              red: 33
            }
          }.with_indifferent_access
        )
      end
    end

    context 'when test_track_schema.yml does not exist' do
      before do
        allow(YAML).to receive(:load_file).with("#{Rails.root}/db/test_track_schema.yml").and_return(nil)
      end

      it 'returns an empty hash' do
        expect(subject.to_h).to eq({})
      end
    end
  end
end
