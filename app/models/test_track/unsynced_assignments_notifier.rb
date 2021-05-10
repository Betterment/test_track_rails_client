class TestTrack::UnsyncedAssignmentsNotifier
  attr_reader :visitor_id, :assignments

  def initialize(opts)
    @visitor_id = opts.delete(:visitor_id)
    @assignments = opts.delete(:assignments)

    %w(visitor_id assignments).each do |param_name|
      raise "#{param_name} must be present" if send(param_name).blank?
    end
    raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def notify
    assignments.each do |assignment|
      TestTrack::AssignmentEventJob.perform_now assignment_job_args(assignment)
    rescue *TestTrack::SERVER_ERRORS => e
      Rails.logger.error "TestTrack failed to notify unsynced assignments, retrying. #{e}"
      TestTrack::AssignmentEventJob.perform_later assignment_job_args(assignment)
    end
  end

  private

  def assignment_job_args(assignment)
    {
      visitor_id: visitor_id,
      assignment: {
        context: assignment.context,
        split_name: assignment.split_name,
        variant: assignment.variant
      }
    }
  end
end
