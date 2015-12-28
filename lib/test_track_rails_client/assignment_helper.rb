module TestTrackRailsClient::AssignmentHelper
  def with_test_track_assignments(assignment_registry) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    split_registry = assignment_registry.each_with_object({}) do |(split_name, variant), s|
      assignment_registry[split_name] = variant.to_s
      s[split_name] = { variant => 100 }
    end
    visitor_attributes = { id: "fake_visitor_id", assignment_registry: assignment_registry, unsynced_splits: [] }

    allow(TestTrack::Remote::Visitor).to receive(:fake_instance_attributes).and_return(visitor_attributes)
    allow(TestTrack::Remote::SplitRegistry).to receive(:fake_instance_attributes).and_return(split_registry)
    TestTrack::Remote::SplitRegistry.reset

    yield
  ensure
    allow(TestTrack::Remote::Visitor).to receive(:fake_instance_attributes).and_call_original
    allow(TestTrack::Remote::SplitRegistry).to receive(:fake_instance_attributes).and_call_original
    TestTrack::Remote::SplitRegistry.reset
  end
end
