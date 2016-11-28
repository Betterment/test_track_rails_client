class TestTrack::UnsyncedAssignmentsNotifier
  attr_reader :mixpanel_distinct_id, :visitor_id, :assignments

  def initialize(opts)
    @visitor_id = opts.delete(:visitor_id)
    @mixpanel_distinct_id = opts.delete(:mixpanel_distinct_id) || visitor_id
    @assignments = opts.delete(:assignments)

    %w(visitor_id assignments).each do |param_name|
      raise "#{param_name} must be present" unless send(param_name).present?
    end
    raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def notify
    assignments.each do |assignment|
      build_notify_assignment_job(assignment).tap do |job|
        begin
          job.perform
        rescue *TestTrack::SERVER_ERRORS => e
          Rails.logger.error "TestTrack failed to notify unsynced assignments, retrying. #{e}"
          Delayed::Job.enqueue(build_notify_assignment_job(assignment))
        end
      end
    end
  end

  private

  def build_notify_assignment_job(assignment)
    TestTrack::NotifyAssignmentJob.new(
      mixpanel_distinct_id: mixpanel_distinct_id,
      visitor_id: visitor_id,
      assignment: assignment
    )
  end
end
