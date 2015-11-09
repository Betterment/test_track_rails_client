module TestTrackRailsClient::AssignmentHelper
  def with_test_track_assignments(assignment_registry) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    split_registry = assignment_registry.each_with_object({}) do |(split_name, variant), s|
      assignment_registry[split_name] = variant.to_s
      s[split_name] = { variant => 100 }
    end

    allow(TestTrack::AssignmentRegistry).to receive(:fake_instance_attributes).and_return(assignment_registry)
    allow(TestTrack::SplitRegistry).to receive(:fake_instance_attributes).and_return(split_registry)
    TestTrack::SplitRegistry.reset

    yield
  ensure
    allow(TestTrack::AssignmentRegistry).to receive(:fake_instance_attributes).and_call_original
    allow(TestTrack::SplitRegistry).to receive(:fake_instance_attributes).and_call_original
    TestTrack::SplitRegistry.reset
  end
end
