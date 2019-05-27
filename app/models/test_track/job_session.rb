class TestTrack::JobSession
  def manage
    raise ArgumentError, "must provide block to `manage`" unless block_given?
    raise "already in use" unless RequestStore[:test_track_job_session].nil?

    RequestStore[:test_track_job_session] = self
    yield
  ensure
    notify_unsynced_assignments!
    RequestStore[:test_track_job_session] = nil
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
      if visitor.loaded? && visitor.unsynced_assignments.present?
        TestTrack::ThreadedVisitorNotifier.new(visitor).notify
      end
    end
  end

  def identity_visitor_map
    @identity_visitor_map ||= {}
  end
end
