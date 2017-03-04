module TestTrackRailsClient::AssignmentHelper
  def stub_test_track_assignments(assignment_registry) # rubocop:disable Metrics/AbcSize
    raise "Cannot stub test track assignments when TestTrack is enabled" if TestTrack.enabled?

    split_registry = TestTrack::Fake::SplitRegistry.instance.to_h.dup
    assignments = []

    assignment_registry.each do |split_name, variant|
      split_registry[split_name] = { variant => 100 } unless split_registry[split_name]
      assignments << { split_name: split_name.to_s, variant: variant.to_s, unsynced: false }
    end

    visitor_attributes = { id: "fake_visitor_id", assignments: assignments }

    allow(TestTrack::Remote::Visitor).to receive(:fake_instance_attributes).and_return(visitor_attributes)
    allow(TestTrack::Remote::SplitRegistry).to receive(:fake_instance_attributes).and_return(split_registry)
  end
end
