require 'rails_helper'

RSpec.describe Tt::Api::ResetsController do
  describe '#update' do
    it 'sets TestTrack::FakeServer seed to provided seed' do
      put :update, seed: '1234321'

      expect(response).to have_http_status(:no_content)
      expect(TestTrack::FakeServer.seed).to eq 1_234_321
    end
  end
end
