class TestTrack::NotifyAssignmentJob
  attr_reader :mixpanel_distinct_id, :visitor_id, :split_name, :variant

  def initialize(opts)
    @mixpanel_distinct_id = opts.delete(:mixpanel_distinct_id)
    @visitor_id = opts.delete(:visitor_id)
    @split_name = opts.delete(:split_name)
    @variant = opts.delete(:variant)

    %w(mixpanel_distinct_id visitor_id split_name variant).each do |param_name|
      raise "#{param_name} must be present" unless send(param_name).present?
    end
    raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def perform
    TestTrack::Remote::Assignment.create!(
      visitor_id: visitor_id,
      split: split_name,
      variant: variant,
      mixpanel_result: mixpanel_track
    )
  end

  private

  def mixpanel_track
    mixpanel.track(
      mixpanel_distinct_id,
      "SplitAssigned",
      "SplitName" => split_name,
      "SplitVariant" => variant,
      "TTVisitorID" => visitor_id
    )
    "success"
  rescue *TestTrack::MIXPANEL_ERRORS
    "failure"
  end

  def mixpanel
    raise "ENV['MIXPANEL_TOKEN'] must be set" unless ENV['MIXPANEL_TOKEN']
    @mixpanel ||= Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
  end
end
