class TestTrack::ThreadedVisitorNotifier
  attr_reader :visitor

  def initialize(visitor)
    @visitor = visitor
  end

  def notify
    payload = {
      visitor_id: visitor.id,
      assignments: visitor.unsynced_assignments
    }
    ActiveSupport::Notifications.instrument('test_track.notify_unsynced_assignments', payload) do
      new_thread_with_request_store do
        TestTrack::UnsyncedAssignmentsNotifier.new(payload).notify
      end
    end
  end

  private

  def new_thread_with_request_store
    Thread.new(RequestStore.store) do |original_store|
      RequestStore.begin!
      RequestStore.store.merge!(original_store)
      yield
    ensure
      RequestStore.end!
      RequestStore.clear!
    end
  end
end
