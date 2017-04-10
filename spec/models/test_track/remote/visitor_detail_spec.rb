require 'rails_helper'

RSpec.describe TestTrack::Remote::VisitorDetail do
  subject { TestTrack::Remote::VisitorDetail.from_identifier('crazy_id', 1) }

  context 'with requests enabled' do
    let(:url) { 'http://testtrack.dev/api/v1/identifier_types/crazy_id/identifiers/1/visitor_detail' }

    before do
      stub_request(:get, url)
        .with(basic_auth: %w(dummy fakepassword))
        .to_return(status: 200, body: {
          assignment_details: [{
            split_name: 'fake_split',
            split_location: 'fake location',
            variant_name: 'variant one',
            variant_description: 'variant description',
            assigned_at: '2017-04-06T00:00:00Z'
          }]
        }.to_json)
    end

    it 'responds to the right request' do
      with_test_track_enabled do
        subject.assignment_details.first.tap do |assignment|
          expect(assignment.split_name).to eq 'fake_split'
          expect(assignment.split_location).to eq 'fake location'
          expect(assignment.variant_name).to eq 'variant one'
          expect(assignment.variant_description).to eq 'variant description'
          expect(assignment.assigned_at).to eq Time.zone.parse('2017-04-06T00:00:00Z')
        end
      end
    end
  end

  context 'without requests enabled' do
    let(:fake_response) do
      {
        assignment_details: [{
          split_name: 'excellent_feature',
          split_location: 'Sign up',
          variant_name: 'Excellent feature enabled',
          variant_description: 'It is so on',
          assigned_at: '2017-04-10T05:00:00Z'
        }]
      }
    end

    before do
      allow(TestTrack::Remote::VisitorDetail).to receive(:fake_instance_attributes).and_return(fake_response)
    end

    it 'responds with the fake attributes' do
      subject.assignment_details.first.tap do |assignment|
        expect(assignment.split_name).to eq 'excellent_feature'
        expect(assignment.split_location).to eq 'Sign up'
        expect(assignment.variant_name).to eq 'Excellent feature enabled'
        expect(assignment.variant_description).to eq 'It is so on'
        expect(assignment.assigned_at).to eq Time.zone.parse('2017-04-10T05:00:00Z')
      end
    end
  end
end
