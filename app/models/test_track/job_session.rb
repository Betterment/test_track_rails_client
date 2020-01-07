class TestTrack::JobSession
  def manage
    raise ArgumentError, "must provide block to `manage`" unless block_given?

    original_job_session = RequestStore[:test_track_job_session]
    RequestStore[:test_track_job_session] = self
    yield
  ensure
    notify_unsynced_assignments!
    RequestStore[:test_track_job_session] = original_job_session
  end

  def visitor_dsl_for(identity)
    raise "must be called within `manage` block" if RequestStore[:test_track_job_session].nil?

    TestTrack::VisitorDSL.new(for_identity(identity))
  end

  private

  def for_identity(identity)
    identity_visitor_map[identity] ||= TestTrack::LazyVisitorByIdentity.new(identity)
  end

  def notify_unsynced_assignments!
    identity_visitor_map.each_value do |visitor|
      TestTrack::ThreadedVisitorNotifier.new(visitor).notify if visitor.loaded? && visitor.unsynced_assignments.present?
    end
  end

  def identity_visitor_map
    @identity_visitor_map ||= {}
  end
end
