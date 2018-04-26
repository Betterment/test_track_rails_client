require 'rails_helper'

RSpec.describe TestTrack::AnalyticsEvent do
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

  describe "#assignment" do
    it "returns the analytics_event's assignment" do
      expect(subject.assignment).to eq assignment
    end
  end

  describe "#visitor_id" do
    it "returns the assignment's visitor_id" do
      expect(subject.visitor_id).to eq 34
    end
  end

  describe "#name" do
    it "returns SplitAssigned" do
      expect(subject.name).to eq "SplitAssigned"
    end

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

      it "returns FeatureGateExperienced" do
        expect(subject.name).to eq "FeatureGateExperienced"
      end
    end
  end

  describe "#properties" do
    it "returns a hash with relevant facts about the assignment" do
      expect(subject.properties).to eq(
        TTVisitorID: 34,
        SplitName: "foo_experiment",
        SplitVariant: "treatment",
        SplitContext: "home_page"
      )
    end
  end
end
