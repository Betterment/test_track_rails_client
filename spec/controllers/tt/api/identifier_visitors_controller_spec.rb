require 'rails_helper'

RSpec.describe Tt::Api::IdentifierVisitorsController do
  describe '#show' do
    it 'returns fake visitor' do
      get :show, identifier_type_name: 'foo', identifier_value: 'buz', format: :json
      expect(assigns(:visitor)).to eq TestTrack::FakeServer.visitor
    end
  end
end
