require 'rails_helper'

RSpec.describe Tt::Api::SplitConfigsController do
  describe '#create' do
    it 'returns no content' do
      post :create
      expect(response).to have_http_status(:no_content)
    end
  end

  describe '#destroy' do
    it 'returns no content' do
      delete :destroy
      expect(response).to have_http_status(:no_content)
    end
  end
end
