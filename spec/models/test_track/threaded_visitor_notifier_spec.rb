require 'rails_helper'

RSpec.describe TestTrack::ThreadedVisitorNotifier do
  let(:visitor) { double(id: "fake_visitor_id", unsynced_assignments: []) }
  let(:unsynced_assignments_notifier) { instance_double(TestTrack::UnsyncedAssignmentsNotifier, notify: true) }
  subject { described_class.new(visitor) }

  before do
    allow(TestTrack::UnsyncedAssignmentsNotifier).to receive(:new).and_return(unsynced_assignments_notifier)
  end

  describe "#notify" do
    it "notifies in background thread" do
      notifier_thread = subject.notify

      expect(notifier_thread).to be_a(Thread)

      # block until thread completes
      notifier_thread.join

      expect(TestTrack::UnsyncedAssignmentsNotifier).to have_received(:new).with(visitor_id: 'fake_visitor_id', assignments: [])

      expect(unsynced_assignments_notifier).to have_received(:notify)
    end

    it "passes along RequestStore contents to the background thread" do
      RequestStore[:stashed_object] = 'stashed object'
      found_object = nil

      allow(unsynced_assignments_notifier).to receive(:notify) do
        found_object = RequestStore[:stashed_object]
      end

      notifier_thread = subject.notify

      # block until thread completes
      notifier_thread.join

      expect(found_object).to eq 'stashed object'
    end
  end
end
