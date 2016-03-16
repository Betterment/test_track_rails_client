require 'rails_helper'

RSpec.describe Tt::Api::VisitorsController do
  describe '#show' do
    it 'returns fake visitor' do
      get :show, id: 1, format: :json
      expect(assigns(:visitor)).to eq TestTrack::FakeServer.visitor
    end
  end
end
