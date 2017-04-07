require 'rails_helper'

RSpec.describe Tt::Api::V1::SplitDetailsController do
  let(:response_json) { JSON.parse(response.body) }

  describe '#show' do
    it 'returns fake split details' do
      get :show, format: :json
      expect(response_json).to eq TestTrack::FakeServer.split_details
    end
  end
end
