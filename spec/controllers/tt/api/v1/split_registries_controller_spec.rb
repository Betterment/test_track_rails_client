require 'rails_helper'

RSpec.describe Tt::Api::V1::SplitRegistriesController do
  describe '#show' do
    it 'returns fake split registry' do
      get :show, format: :json
      expect(assigns(:active_splits)).to eq TestTrack::FakeServer.split_registry
    end
  end
end
