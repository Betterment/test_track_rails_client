require 'rails_helper'

RSpec.describe TestTrack::Remote::AssignmentDetail do
  before do
    stub_request(:get, url)
      .with(basic_auth: %w(dummy password))
      .to_return(status: 200, body: [{
        split_name: 'fake_split',
        split_location: 'fake location',
        variant_name: 'variant one',
        variant_description: 'variant description',
        assigned_at: '2017-04-06T00:00:00Z'
      }].to_json)
  end

  let(:visitor) { Visitor.new(visitor_id: 'fake_visitor_id') }

  context 'with requests enabled' do
    let(:url) { 'http://testtrack.dev/api/v1/visitors/fake_visitor_id/assignment_details' }
    subject { visitor.assignment_details.first }

    it 'has the correct attributes' do
      expect(subject.split_name).to eq 'fake_split'
      expect(subject.split_location).to eq 'fake location'
      expect(subject.variant_name).to eq 'variant one'
      expect(subject.variant_description).to eq 'variant description'
      expect(subject.assigned_at).to eq Time.zone.parse('2017-04-06T00:00:00Z')
    end
  end
end
