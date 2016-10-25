module TestTrack::Analytics
  class MixpanelClient
    delegate :alias, to: :mixpanel

    def track_assignment(visitor_id, assignment, params = {})
      distinct_id = params.delete(:mixpanel_distinct_id) || visitor_id
      mixpanel.track(distinct_id, 'SplitAssigned', split_properties(assignment).merge(TTVisitorID: visitor_id))
    end

    private

    def mixpanel
      raise "ENV['MIXPANEL_TOKEN'] must be set" unless ENV['MIXPANEL_TOKEN']
      @mixpanel ||= Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
    end

    def split_properties(assignment)
      {
        SplitName: assignment.split_name,
        SplitVariant: assignment.variant,
        SplitContext: assignment.context
      }
    end
  end
end
