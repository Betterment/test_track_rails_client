require 'rails_helper'

RSpec.describe TestTrack::AnalyticsEvent do
  context "with a feature gate" do
    let(:assignment) do
      instance_double(
        TestTrack::Assignment,
        visitor_id: 34,
        split_name: "foo_enabled",
        variant: "true",
        context: "home_page",
        feature_gate?: true
      )
    end

    subject { described_class.new(assignment) }

    it "has a name of FeatureGateExperienced" do
      expect(subject.name).to eq "FeatureGateExperienced"
    end

    it "has a well-formed properties" do
      expect(subject.properties).to eq(
        TTVisitorID: 34,
        SplitName: "foo_enabled",
        SplitVariant: "true",
        SplitContext: "home_page"
      )
    end
  end

  context "with an experiment" do
    let(:assignment) do
      instance_double(
        TestTrack::Assignment,
        visitor_id: 34,
        split_name: "foo_experiment",
        variant: "treatment",
        context: "home_page",
        feature_gate?: false
      )
    end

    subject { described_class.new(assignment) }

    it "has a name of SplitAssigned" do
      expect(subject.name).to eq "SplitAssigned"
    end
  end
end
