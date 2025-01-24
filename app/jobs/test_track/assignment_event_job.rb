module TestTrack
  class AssignmentEventJob < ApplicationJob
    attr_reader :visitor_id, :assignment

    def perform(visitor_id:, split_name:, variant:, context:)
      raise "visitor_id must be present" if visitor_id.blank?
      raise "split_name must be present" if visitor_id.blank?

      @visitor_id = visitor_id
      @assignment = build_assignment(visitor_id, split_name, variant, context)

      create_assignment_event!
    end

    private

    def build_assignment(visitor_id, split_name, variant, context)
      assignment = Assignment.new(
        visitor: Visitor.new(id: visitor_id),
        split_name:
      )
      assignment.variant = variant
      assignment.context = context
      assignment
    end

    def create_assignment_event!
      tracking_result = maybe_track
      unless assignment.feature_gate?
        Remote::AssignmentEvent.create!(
          visitor_id:,
          split_name: assignment.split_name,
          context: assignment.context,
          mixpanel_result: tracking_result
        )
      end
    end

    def maybe_track
      return "failure" unless TestTrack.enabled?
      return "success" if skip_analytics_event?

      result = TestTrack.analytics.track(AnalyticsEvent.new(visitor_id, assignment))
      result ? "success" : "failure"
    end

    def skip_analytics_event?
      assignment.feature_gate? && skip_experience_event?
    end

    def skip_experience_event?
      skip_all_experience_events? || !sample_event?
    end

    def skip_all_experience_events?
      experience_sampling_weight.zero?
    end

    def sample_event?
      Kernel.rand(experience_sampling_weight).zero?
    end

    def experience_sampling_weight
      @experience_sampling_weight ||= split_registry.experience_sampling_weight
    end

    def split_registry
      @split_registry ||= SplitRegistry.from_remote
    end
  end
end
