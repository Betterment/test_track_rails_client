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
    tracking_result = track
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

  def track
    return "failure" unless TestTrack.enabled?
    result = TestTrack.analytics.track_assignment(visitor_id, assignment)
    result ? "success" : "failure"
  end
end
