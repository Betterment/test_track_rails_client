class TestTrack::NotifyAssignmentJob
  attr_reader :mixpanel_distinct_id, :visitor_id, :assignment

  def initialize(opts)
    @mixpanel_distinct_id = opts.delete(:mixpanel_distinct_id)
    @visitor_id = opts.delete(:visitor_id)
    @assignment = opts.delete(:assignment)

    %w(mixpanel_distinct_id visitor_id assignment).each do |param_name|
      raise "#{param_name} must be present" unless send(param_name).present?
    end
    raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def perform
    TestTrack::Remote::Assignment.create!(
      visitor_id: visitor_id,
      split: assignment.split_name,
      variant: assignment.variant,
      mixpanel_result: mixpanel_track
    )
  end

  private

  def mixpanel_track
    return "failure" unless TestTrack.enabled?
    mixpanel.track(mixpanel_distinct_id, "SplitAssigned", mixpanel_track_properties)
    "success"
  rescue *TestTrack::MIXPANEL_ERRORS
    "failure"
  end

  def mixpanel_track_properties
    {
      "SplitName" => assignment.split_name,
      "SplitVariant" => assignment.variant,
      "TTVisitorID" => visitor_id
    }
  end

  def mixpanel
    raise "ENV['MIXPANEL_TOKEN'] must be set" unless ENV['MIXPANEL_TOKEN']
    @mixpanel ||= Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
  end
end
