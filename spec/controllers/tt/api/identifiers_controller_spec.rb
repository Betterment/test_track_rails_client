require 'rails_helper'

RSpec.describe Tt::Api::IdentifierVisitorsController do
  describe '#create' do
    it 'returns fake visitor' do
      post :create
      expect(assigns(:visitor)).to eq TestTrack::FakeServer.visitor
    end
  end
end
