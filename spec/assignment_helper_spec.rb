require 'rails_helper'
require 'test_track_rails_client/rspec_helpers'

RSpec.describe TestTrackRailsClient::AssignmentHelper do
  describe "#with_test_track_assignments" do
    it "overrides assignment registry to match" do
      with_test_track_assignments(foo: :bar) do
        expect(TestTrack::Remote::Visitor.find(201).assignment_registry).to eq('foo' => 'bar')
      end
    end

    it "overrides split registry with a trivial split set" do
      with_test_track_assignments(foo: :bar) do
        expect(TestTrack::Remote::SplitRegistry.to_hash).to eq('foo' => { 'bar' => 100 })
      end
    end

    it "resets assignment registry when done" do
      with_test_track_assignments(foo: :bar) do
      end
      expect(TestTrack::Remote::Visitor.find(201).assignment_registry).not_to eq('foo' => 'bar')
    end

    it "resets split registry when done" do
      with_test_track_assignments(foo: :bar) do
      end
      expect(TestTrack::Remote::SplitRegistry.to_hash).not_to eq('foo' => { 'bar' => 100 })
    end

    it "returns the result of the block" do
      expect(with_test_track_assignments(biz: :bop) { "baz" }).to eq "baz"
    end
  end
end
