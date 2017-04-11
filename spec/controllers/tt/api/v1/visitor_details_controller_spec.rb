require 'rails_helper'

RSpec.describe Tt::Api::V1::VisitorDetailsController do
  let(:response_json) { JSON.parse(response.body, symbolize_names: true) }

  describe '#show' do
    it 'returns fake visitor details' do
      get :show, identifier_type_name: 'crazy_id', identifier_value: 1

      expected_response = {
        assignment_details: [
          {
            split_name: 'really_cool_feature',
            split_location: 'Home page',
            variant_name: 'Enabled',
            variant_description: 'The feature is enabled',
            assigned_at: '2017-04-11T00:00:00Z'
          }
        ]
      }

      expect(response_json).to eq expected_response
    end
  end
end
