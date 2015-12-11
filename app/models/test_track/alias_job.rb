require 'mixpanel-ruby'

class TestTrack::AliasJob
  attr_reader :mixpanel_distinct_id, :visitor_id

  def initialize(opts)
    @mixpanel_distinct_id = opts.delete(:mixpanel_distinct_id)
    @visitor_id = opts.delete(:visitor_id)

    %w(mixpanel_distinct_id visitor_id).each do |param_name|
      raise "#{param_name} must be present" unless send(param_name).present?
    end
    raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def perform
    mixpanel.alias(visitor_id, mixpanel_distinct_id)
  end

  private

  def mixpanel
    raise "ENV['MIXPANEL_TOKEN'] must be set" unless ENV['MIXPANEL_TOKEN']
    @mixpanel ||= Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
  end
end
