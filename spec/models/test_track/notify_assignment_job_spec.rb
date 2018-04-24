require 'rails_helper'

RSpec.describe TestTrack::NotifyAssignmentJob do
  let(:feature_gate) { false }
  let(:assignment) do
    instance_double(
      TestTrack::Assignment,
      split_name: "phaser",
      variant: "stun",
      context: "the_context",
      feature_gate?: feature_gate
    )
  end
  let(:params) do
    {
      visitor_id: "fake_visitor_id",
      assignment: assignment
    }
  end

  subject { described_class.new(params) }

  it "blows up with empty visitor id" do
    expect { described_class.new(params.merge(visitor_id: nil)) }
      .to raise_error(/visitor_id/)
  end

  it "blows up with empty assignment" do
    expect { described_class.new(params.merge(assignment: nil)) }
      .to raise_error(/assignment/)
  end

  it "blows up with unknown opts" do
    expect { described_class.new(params.merge(extra_stuff: true)) }
      .to raise_error(/unknown opts/)
  end

  describe "#perform" do
    let(:remote_assignment) { instance_double(TestTrack::Remote::AssignmentEvent) }
    before do
      allow(TestTrack::Remote::AssignmentEvent).to receive(:create!).and_return(remote_assignment)
      allow(TestTrack.analytics).to receive(:track_assignment).and_return(true)
    end

    it "does not send analytics events when test track is not enabled" do
      subject.perform
      expect(TestTrack.analytics).to_not have_received(:track_assignment)
    end

    it "sends analytics event" do
      with_test_track_enabled { subject.perform }

      expect(TestTrack.analytics).to have_received(:track_assignment).with(
        "fake_visitor_id",
        assignment
      )
    end

    it "sends test_track assignment" do
      with_test_track_enabled { subject.perform }

      expect(TestTrack::Remote::AssignmentEvent).to have_received(:create!).with(
        visitor_id: 'fake_visitor_id',
        split_name: 'phaser',
        context: 'the_context',
        mixpanel_result: 'success'
      )
    end

    context "with a feature gate" do
      let(:feature_gate) { true }

      it "does not send test_track assignments" do
        with_test_track_enabled { subject.perform }

        expect(TestTrack::Remote::AssignmentEvent).not_to have_received(:create!)
      end

      it "still sends analytics events" do
        with_test_track_enabled { subject.perform }

        expect(TestTrack.analytics).to have_received(:track_assignment).with(
          "fake_visitor_id",
          assignment
        )
      end
    end

    context "analytics client fails" do
      before do
        allow(TestTrack.analytics).to receive(:track_assignment).and_return(false)
      end

      it "sends test_track assignment with mixpanel_result set to failure" do
        with_test_track_enabled { subject.perform }

        expect(TestTrack::Remote::AssignmentEvent).to have_received(:create!).with(
          visitor_id: 'fake_visitor_id',
          split_name: 'phaser',
          context: 'the_context',
          mixpanel_result: 'failure'
        )
      end
    end
  end
end
