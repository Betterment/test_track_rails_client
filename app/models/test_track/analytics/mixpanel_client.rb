module TestTrack::Analytics
  class MixpanelClient
    delegate :alias, to: :mixpanel

    def track(visitor_id, metric_name, properties = {})
      mixpanel.track(visitor_id, metric_name, properties)
    end

    private

    def mixpanel
      raise "ENV['MIXPANEL_TOKEN'] must be set" unless ENV['MIXPANEL_TOKEN']
      @mixpanel ||= Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
    end
  end
end
