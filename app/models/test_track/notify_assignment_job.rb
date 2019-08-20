class TestTrack::NotifyAssignmentJob
  attr_reader :visitor_id, :assignment

  def initialize(opts)
    @visitor_id = opts.delete(:visitor_id)
    @assignment = opts.delete(:assignment)

    %w(visitor_id assignment).each do |param_name|
      raise "#{param_name} must be present" if send(param_name).blank?
    end
    raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def perform
    tracking_result = maybe_track
    unless assignment.feature_gate?
      TestTrack::Remote::AssignmentEvent.create!(
        visitor_id: visitor_id,
        split_name: assignment.split_name,
        context: assignment.context,
        mixpanel_result: tracking_result
      )
    end
  end

  private

  def maybe_track
    return "failure" unless TestTrack.enabled?
    return "success" if skip_analytics_event?
    result = TestTrack.analytics.track(TestTrack::AnalyticsEvent.new(visitor_id, assignment))
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
    @split_registry ||= TestTrack::SplitRegistry.from_remote
  end
end
