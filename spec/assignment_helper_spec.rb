require 'rails_helper'
require 'test_track_rails_client/rspec_helpers'

RSpec.describe TestTrackRailsClient::AssignmentHelper do
  describe "#stub_test_track_assignments" do
    it "overrides assignment registry to match" do
      stub_test_track_assignments(foo: :bar)

      TestTrack::Remote::Visitor.find(201).assignments.first.tap do |assignment|
        expect(assignment.split_name).to eq('foo')
        expect(assignment.variant).to eq('bar')
      end
    end

    it "overrides split registry with a trivial split set" do
      stub_test_track_assignments(foo: :bar)

      expect(TestTrack::Remote::SplitRegistry.to_hash).to eq('foo' => { 'bar' => 100 })
    end

    it 'raises if test track is enabled' do
      with_test_track_enabled do
        expect { stub_test_track_assignments(foo: :bar) }.to raise_error(/Cannot stub test track assignments/)
      end
    end
  end
end
