class TestTrack::WebSessionVisitorRepository
  attr_reader :current_identity, :unauthenticated_visitor_id

  def initialize(current_identity:, unauthenticated_visitor_id:)
    @current_identity = current_identity
    @unauthenticated_visitor_id = unauthenticated_visitor_id
  end

  def current
    if current_identity
      for_identity(current_identity)
    else
      unauthenticated
    end
  end

  def for_identity(identity)
    identity_visitor_map[identity] ||= TestTrack::LazyVisitorByIdentity.new(identity)
  end

  def forget_unauthenticated!
    @unauthenticated = TestTrack::Visitor.new
  end

  def authenticate!(identity)
    @current_identity = identity
    identity_visitor_map[identity] = unauthenticated
    unauthenticated.link_identity!(identity)
  end

  def all
    identity_visitor_map.values.to_set << current
  end

  def notify_unsynced_assignments!
    all.each do |visitor|
      if visitor.loaded? && visitor.unsynced_assignments.present?
        TestTrack::ThreadedVisitorNotifier.new(visitor).notify
      end
    end
  end

  private

  def unauthenticated
    @unauthenticated ||= TestTrack::Visitor.new(id: unauthenticated_visitor_id)
  end

  def identity_visitor_map
    @identity_visitor_map ||= {}
  end
end
