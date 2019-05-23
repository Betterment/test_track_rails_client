class TestTrack::BackgroundSessionVisitorRepository
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

  private

  def identity_visitor_map
    @identity_visitor_map ||= {}
  end
end
