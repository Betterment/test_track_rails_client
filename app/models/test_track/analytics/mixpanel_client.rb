module TestTrack::Analytics
  class MixpanelClient
    def track(analytics_event)
      mixpanel.track(analytics_event.visitor_id, analytics_event.name, analytics_event.properties)
    end

    private

    def mixpanel
      raise "ENV['MIXPANEL_TOKEN'] must be set" unless ENV['MIXPANEL_TOKEN']

      @mixpanel ||= Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
    end
  end
end
