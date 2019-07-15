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

      expect(TestTrack::Remote::SplitRegistry.to_hash['splits']).to include(
        'foo' => { 'weights' => { 'bar' => 100 }, 'feature_gate' => false }
      )
    end

    it 'sets feature_gate based on the split name' do
      stub_test_track_assignments(foo_enabled: :bar)

      expect(TestTrack::Remote::SplitRegistry.to_hash['splits']).to include(
        'foo_enabled' => { 'weights' => { 'bar' => 100 }, 'feature_gate' => true }
      )
    end

    context 'with a prefixed split name already in the split registry' do
      let(:fake_split_registry) do
        instance_double(TestTrack::Fake::SplitRegistry, to_h: { 'splits' => { 'dummy.foo' => { 'weights' => { 'bar' => 100 } } } })
      end

      before { allow(TestTrack::Fake::SplitRegistry).to receive(:instance).and_return(fake_split_registry) }

      it 'overrides assignment registry to match and overrides split registry' do
        stub_test_track_assignments(foo: :bar)

        TestTrack::Remote::Visitor.find(201).assignments.first.tap do |assignment|
          expect(assignment.split_name).to eq('dummy.foo')
          expect(assignment.variant).to eq('bar')
        end

        expect(TestTrack::Remote::SplitRegistry.to_hash['splits']).to include(
          'dummy.foo' => { 'weights' => { 'bar' => 100 }, 'feature_gate' => false }
        )
      end
    end

    it 'raises if test track is enabled' do
      with_test_track_enabled do
        expect { stub_test_track_assignments(foo: :bar) }.to raise_error(/Cannot stub test track assignments/)
      end
    end

    it 'works correctly with a vary call' do
      stub_test_track_assignments(foo: :bar)

      visitor = TestTrack::Visitor.new
      expect {
        visitor.vary(:foo, context: :spec) do |v|
          v.when :bar do
            # noop
          end
          v.default :baz do
            raise "this branch shouldn't be executed"
          end
        end
      }.not_to raise_error
    end
  end
end
