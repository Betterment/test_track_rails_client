require 'rails_helper'

RSpec.describe Tt::Api::AssignmentRegistriesController do
  describe '#show' do
    it 'returns fake server assignments' do
      get :show, visitor_id: 1, format: :json
      expect(assigns(:assignments)).to eq TestTrack::FakeServer.assignments
    end
  end
end
