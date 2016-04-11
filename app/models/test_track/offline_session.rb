class TestTrack::OfflineSession
  def initialize(identifier_type, identifier_value)
    @identifier_type = identifier_type
    @identifier_value = identifier_value
  end

  def self.with_visitor_for(identifier_type, identifier_value)
    raise ArgumentError, "must provide block to `with_visitor_for`" unless block_given?

    new(identifier_type, identifier_value).send :manage do |visitor_dsl|
      yield visitor_dsl
    end
  end

  private

  attr_reader :identifier_type, :identifier_value

  def visitor
    @visitor ||= TestTrack::Visitor.new(
      id: remote_visitor.id,
      assignments: remote_visitor.assignments
    )
  end

  def remote_visitor
    @remote_visitor ||= TestTrack::Remote::IdentifierVisitor.from_identifier(identifier_type, identifier_value)
  end

  def manage
    yield TestTrack::VisitorDSL.new(visitor)
  ensure
    notify_unsynced_assignments! if unsynced_assignments?
  end

  def unsynced_assignments?
    visitor.unsynced_assignments.present?
  end

  def notify_unsynced_assignments!
    TestTrack::UnsyncedAssignmentsNotifier.new(
      mixpanel_distinct_id: visitor.id,
      visitor_id: visitor.id,
      assignments: visitor.unsynced_assignments
    ).notify
  end
end
