require 'rails_helper'

RSpec.describe Tt::Api::VisitorsController do
  describe '#show' do
    it 'returns fake visitor' do
      xhr :show
      expect(assigns(:visitor)).to eq TestTrack::FakeServer.visitor
    end
  end
end
