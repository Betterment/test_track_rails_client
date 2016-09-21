class TestTrack::NotifyAssignmentJob
  attr_reader :mixpanel_distinct_id, :visitor_id, :assignment

  def initialize(opts)
    @visitor_id = opts.delete(:visitor_id)
    @mixpanel_distinct_id = opts.delete(:mixpanel_distinct_id)
    @assignment = opts.delete(:assignment)

    %w(visitor_id assignment).each do |param_name|
      raise "#{param_name} must be present" unless send(param_name).present?
    end
    raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def perform
    TestTrack::Remote::Assignment.create!(
      visitor_id: visitor_id,
      split_name: assignment.split_name,
      variant: assignment.variant,
      context: assignment.context,
      mixpanel_result: track
    )
  end

  private

  def track
    return "failure" unless TestTrack.enabled?
    result = TestTrack.analytics.track_assignment(visitor_id, assignment, mixpanel_distinct_id: mixpanel_distinct_id)
    result ? "success" : "failure"
  end
end
