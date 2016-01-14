require 'rails_helper'

RSpec.describe TestTrack::UnsyncedAssignmentsNotifier do
  let(:params) do
    {
      mixpanel_distinct_id: "fake_mixpanel_id",
      visitor_id: "fake_visitor_id",
      assignments: { "phaser" => "stun", "alert" => "yellow" }
    }
  end

  subject { described_class.new(params) }

  it "blows up with empty mixpanel_distinct_id" do
    expect { described_class.new(params.merge(mixpanel_distinct_id: '')) }
      .to raise_error(/mixpanel_distinct_id/)
  end

  it "blows up with empty visitor id" do
    expect { described_class.new(params.merge(visitor_id: nil)) }
      .to raise_error(/visitor_id/)
  end

  it "blows up with empty assignments" do
    expect { described_class.new(params.merge(assignments: {})) }
      .to raise_error(/assignments/)
  end

  it "blows up with unknown opts" do
    expect { described_class.new(params.merge(extra_stuff: true)) }
      .to raise_error(/unknown opts/)
  end

  describe "#notify" do
    let(:phaser_job) { instance_double(TestTrack::NotifyAssignmentJob, perform: true) }
    let(:alert_job) { instance_double(TestTrack::NotifyAssignmentJob, perform: true) }

    before do
      allow(TestTrack::NotifyAssignmentJob).to receive(:new).with(
        mixpanel_distinct_id: "fake_mixpanel_id",
        visitor_id: "fake_visitor_id",
        split_name: "phaser",
        variant: "stun"
      ).and_return(phaser_job)

      allow(TestTrack::NotifyAssignmentJob).to receive(:new).with(
        mixpanel_distinct_id: "fake_mixpanel_id",
        visitor_id: "fake_visitor_id",
        split_name: "alert",
        variant: "yellow"
      ).and_return(alert_job)

      allow(Delayed::Job).to receive(:enqueue).and_return(true)
    end

    it "creates and performs NotifyAssignmentJob for each assignment" do
      subject.notify

      expect(TestTrack::NotifyAssignmentJob).to have_received(:new).exactly(:twice)

      expect(phaser_job).to have_received(:perform)
      expect(alert_job).to have_received(:perform)
    end

    it "enqueues a NotifyAssignmentJob if it blows up" do
      allow(phaser_job).to receive(:perform) { raise(Faraday::TimeoutError, "Womp womp") }

      subject.notify

      expect(Delayed::Job).to have_received(:enqueue).with(phaser_job)
      expect(Delayed::Job).not_to have_received(:enqueue).with(alert_job)
    end

    it "enqueues a NotifyAssignmentJob without the Mixpanel::Tracker instance serialized" do
      allow(TestTrack::NotifyAssignmentJob).to receive(:new).and_call_original

      mixpanel = Mixpanel::Tracker.new(ENV['MIXPANEL_TOKEN'])
      allow(mixpanel).to receive(:track).and_return(true)
      allow(Mixpanel::Tracker).to receive(:new).and_return(mixpanel)

      allow(TestTrack::Remote::Assignment).to receive(:create!) { raise(Faraday::TimeoutError, "Womp womp") }
      allow(Delayed::Job).to receive(:enqueue).and_call_original

      with_test_track_enabled do
        with_jobs_delayed(work_off: false) do
          described_class.new(params.merge(assignments: { "phaser" => "stun" })).notify
        end
      end

      expect(Delayed::Job.first.handler).to eq <<-YML
--- !ruby/object:TestTrack::NotifyAssignmentJob
mixpanel_distinct_id: fake_mixpanel_id
visitor_id: fake_visitor_id
split_name: phaser
variant: stun
YML
    end
  end
end
