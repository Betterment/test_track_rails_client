class TestTrack::BackgroundSession
  def manage
    yield
  ensure
    visitors.notify_unsynced_assignments!
  end

  def visitor_dsl_for(identity)
    TestTrack::VisitorDSL.new(visitors.for_identity(identity))
  end

  private

  def visitors
    @visitors ||= TestTrack::SessionVisitorRepository.new(
      current_identity: current_identity,
      unauthenticated_visitor_id: unauthenticated_visitor_id
    )
  end
end
