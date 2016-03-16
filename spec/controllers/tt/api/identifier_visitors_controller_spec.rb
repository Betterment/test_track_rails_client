require 'rails_helper'

RSpec.describe Tt::Api::IdentifierVisitorsController do
  describe '#show' do
    it 'returns fake visitor' do
      get :show
      expect(assigns(:visitor)).to eq TestTrack::FakeServer.visitor
    end
  end
end
