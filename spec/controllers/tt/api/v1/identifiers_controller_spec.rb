require 'rails_helper'

RSpec.describe Tt::Api::V1::IdentifiersController do
  describe '#create' do
    it 'returns fake visitor' do
      post :create, format: :json
      expect(assigns(:visitor)).to eq TestTrack::FakeServer.visitor
    end
  end
end
