class TestTrack::UnsyncedAssignmentsNotifier
  attr_reader :mixpanel_distinct_id, :visitor_id, :assignments

  def initialize(opts)
    @mixpanel_distinct_id = opts.delete(:mixpanel_distinct_id)
    @visitor_id = opts.delete(:visitor_id)
    @assignments = opts.delete(:assignments)

    %w(mixpanel_distinct_id visitor_id assignments).each do |param_name|
      raise "#{param_name} must be present" unless send(param_name).present?
    end
    raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def notify
    assignments.each do |split_name, variant|
      build_notify_assignment_job(split_name, variant).tap do |job|
        begin
          job.perform
        rescue *TestTrack::SERVER_ERRORS
          Delayed::Job.enqueue(build_notify_assignment_job(split_name, variant))
        end
      end
    end
  end

  private

  def build_notify_assignment_job(split_name, variant)
    TestTrack::NotifyAssignmentJob.new(
      mixpanel_distinct_id: mixpanel_distinct_id,
      visitor_id: visitor_id,
      split_name: split_name,
      variant: variant
    )
  end
end
