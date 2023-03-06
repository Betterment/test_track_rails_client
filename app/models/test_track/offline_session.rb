class TestTrack::OfflineSession
  def initialize(remote_visitor)
    @remote_visitor = remote_visitor
  end

  def self.with_visitor_for(identifier_type, identifier_value, &block)
    raise ArgumentError, "must provide block to `with_visitor_for`" unless block_given?

    remote_visitor = TestTrack::Remote::Visitor.from_identifier(identifier_type, identifier_value)

    new(remote_visitor).send(:manage, &block)
  end

  def self.with_visitor_id(visitor_id, &block)
    raise ArgumentError, "must provide block to `with_visitor_id`" unless block_given?

    remote_visitor = TestTrack::Remote::Visitor.find(visitor_id)

    new(remote_visitor).send(:manage, &block)
  end

  private

  attr_reader :remote_visitor

  def visitor
    @visitor ||= TestTrack::Visitor.new(
      id: remote_visitor.id,
      assignments: remote_visitor.assignments
    )
  end

  def manage
    yield TestTrack::VisitorDsl.new(visitor)
  ensure
    notify_unsynced_assignments!
  end

  def unsynced_assignments?
    visitor.unsynced_assignments.present?
  end

  def notify_unsynced_assignments!
    if unsynced_assignments?
      TestTrack::UnsyncedAssignmentsNotifier.new(
        visitor_id: visitor.id,
        assignments: visitor.unsynced_assignments
      ).notify
    end
  end
end
