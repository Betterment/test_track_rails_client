class TestTrack::JobSession
  def manage
    raise ArgumentError, "must provide block to `manage`" unless block_given?

    yield
  ensure
    notify_unsynced_assignments!
  end

  def visitor_dsl_for(identity)
    TestTrack::VisitorDSL.new(for_identity(identity))
  end

  private

  def for_identity(identity)
    identity_visitor_map[identity] ||= TestTrack::LazyVisitorByIdentity.new(identity)
  end

  def notify_unsynced_assignments!
    identity_visitor_map.values.each do |visitor|
      if visitor.loaded? && visitor.unsynced_assignments.present?
        TestTrack::ThreadedVisitorNotifier.new(visitor).notify
      end
    end
  end

  def identity_visitor_map
    @identity_visitor_map ||= {}
  end
end
