require 'rails_helper'

RSpec.describe Tt::Api::V1::SplitDetailsController do
  let(:response_json) { JSON.parse(response.body, symbolize_names: true) }

  describe '#show' do
    it 'returns fake split details' do
      get :show, id: "great_split", format: :json

      expected_response = {
        name: "great_split",
        hypothesis: "user will interact more with blue banner",
        location: "home screen",
        platform: "mobile",
        owner: "mobile team",
        assignment_criteria: "user has mobile app",
        description: "banner test to see if users will interact more"
      }

      expect(response_json).to eq expected_response
    end
  end
end
