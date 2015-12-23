require 'mixpanel-ruby'

class TestTrack::CreateAliasJob
  attr_reader :existing_mixpanel_id, :alias_id

  def initialize(opts)
    @existing_mixpanel_id = opts.delete(:existing_mixpanel_id)
    @alias_id = opts.delete(:alias_id)

    %w(existing_mixpanel_id alias_id).each do |param_name|
      raise "#{param_name} must be present" unless send(param_name).present?
    end
    raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def perform
    mixpanel.alias(alias_id, existing_mixpanel_id)
  rescue Mixpanel::ConnectionError
    raise "mixpanel alias failed for existing_mixpanel_id: #{existing_mixpanel_id}, alias_id: #{alias_id}"
  end

  private

  def mixpanel
    raise "ENV['MIXPANEL_TOKEN'] must be set" unless ENV['MIXPANEL_TOKEN']
    @mixpanel ||= Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
  end
end
