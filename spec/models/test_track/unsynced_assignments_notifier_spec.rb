require 'rails_helper'

RSpec.describe TestTrack::UnsyncedAssignmentsNotifier do
  let(:phaser_assignment_opts) { { split_name: "phaser", variant: "stun", context: "the_context" } }
  let(:phaser_assignment) { instance_double(TestTrack::Assignment, phaser_assignment_opts) }
  let(:alert_assignment_opts) { { split_name: "alert", variant: "yellow", context: "the_context" } }
  let(:alert_assignment) { instance_double(TestTrack::Assignment, alert_assignment_opts) }
  let(:params) do
    {
      visitor_id: "fake_visitor_id",
      assignments: [phaser_assignment, alert_assignment]
    }
  end

  subject { described_class.new(params) }

  it "blows up with empty visitor id" do
    expect { described_class.new(params.merge(visitor_id: nil)) }
      .to raise_error(/visitor_id/)
  end

  it "blows up with empty assignments" do
    expect { described_class.new(params.merge(assignments: [])) }
      .to raise_error(/assignments/)
  end

  it "blows up with unknown opts" do
    expect { described_class.new(params.merge(extra_stuff: true)) }
      .to raise_error(/unknown opts/)
  end

  describe "#notify" do
    it "creates and performs NotifyAssignmentJob for each assignment" do
      allow(TestTrack::AssignmentEventJob).to receive(:perform_now).and_return(true)
      allow(TestTrack::AssignmentEventJob).to receive(:perform_later) { raise("unexpected!") }

      subject.notify

      expect(TestTrack::AssignmentEventJob).to have_received(:perform_now).with(
        phaser_assignment_opts.merge(visitor_id: "fake_visitor_id")
      )
      expect(TestTrack::AssignmentEventJob).to have_received(:perform_now).with(
        alert_assignment_opts.merge(visitor_id: "fake_visitor_id")
      )
    end

    it "enqueues a NotifyAssignmentJob if it blows up" do
      allow(TestTrack::AssignmentEventJob).to receive(:perform_now) { raise(Faraday::TimeoutError, "Womp womp") }
      allow(TestTrack::AssignmentEventJob).to receive(:perform_later).and_return(true)

      subject.notify

      expect(TestTrack::AssignmentEventJob).to have_received(:perform_later).with(
        phaser_assignment_opts.merge(visitor_id: "fake_visitor_id")
      )
      expect(TestTrack::AssignmentEventJob).to have_received(:perform_later).with(
        alert_assignment_opts.merge(visitor_id: "fake_visitor_id")
      )
    end
  end
end
