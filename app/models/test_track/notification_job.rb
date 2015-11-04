require 'mixpanel-ruby'

class TestTrack::NotificationJob
  attr_reader :mixpanel_distinct_id, :visitor_id, :new_assignments

  def initialize(opts)
    @mixpanel_distinct_id = opts.delete(:mixpanel_distinct_id)
    @visitor_id = opts.delete(:visitor_id)
    @new_assignments = opts.delete(:new_assignments)

    %w(mixpanel_distinct_id visitor_id new_assignments).each do |param_name|
      raise "#{param_name} must be present" unless send(param_name).present?
    end
    raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def perform
    new_assignments.each do |split_name, variant|
      TestTrack::Assignment.create!(visitor_id: visitor_id, split_name: split_name, variant: variant)
      mixpanel.track(
        mixpanel_distinct_id,
        "SplitAssigned",
        "SplitName" => split_name,
        "SplitVariant" => variant,
        "TTVisitorID" => visitor_id
      )
    end
  end

  private

  def mixpanel
    raise "ENV['MIXPANEL_TOKEN'] must be set" unless ENV['MIXPANEL_TOKEN']
    @mixpanel ||= Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
  end
end
