module TestTrackRailsClient::AssignmentHelper
  def stub_test_track_assignments(assignment_registry) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    raise "Cannot stub test track assignments when TestTrack is enabled" if TestTrack.enabled?

    split_registry = TestTrack::Fake::SplitRegistry.instance.to_h.deep_dup
    assignments = []
    app_name = URI.parse(TestTrack.private_url).user

    assignment_registry.each do |split_name, variant|
      prefixed_split_name = "#{app_name}.#{split_name}"
      split_name = if split_registry['splits'].key?(prefixed_split_name)
                     prefixed_split_name
                   else
                     split_name.to_s
                   end

      split_registry['splits'][split_name] = {
        weights: { variant.to_s => 100 },
        feature_gate: split_name.end_with?('_enabled')
      }
      assignments << { split_name:, variant: variant.to_s, unsynced: false }
    end

    visitor_attributes = { id: "fake_visitor_id", assignments: }

    allow(TestTrack::Remote::Visitor).to receive(:fake_instance_attributes).and_return(visitor_attributes)
    allow(TestTrack::Remote::SplitRegistry).to receive(:fake_instance_attributes).and_return(split_registry)
  end
end
