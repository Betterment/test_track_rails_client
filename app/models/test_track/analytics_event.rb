module TestTrack
  class AnalyticsEvent
    attr_reader :assignment

    delegate :visitor_id, to: :assignment

    def initialize(assignment)
      @assignment = assignment
    end

    def name
      if assignment.feature_gate?
        'FeatureGateExperienced'
      else
        'SplitAssigned'
      end
    end

    def properties
      {
        TTVisitorID: visitor_id,
        SplitName: assignment.split_name,
        SplitVariant: assignment.variant,
        SplitContext: assignment.context
      }
    end
  end
end
