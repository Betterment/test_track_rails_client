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
      assignment_registry: remote_visitor.assignment_registry,
      unsynced_splits: remote_visitor.unsynced_splits
    )
  end

  def remote_visitor
    @remote_visitor ||= TestTrack::Remote::IdentifierVisitor.from_identifier(identifier_type, identifier_value)
  end

  def manage
    yield TestTrack::VisitorDSL.new(visitor)
  ensure
    notify_new_assignments! if new_assignments?
  end

  def new_assignments?
    visitor.new_assignments.present?
  end

  def notify_new_assignments!
    notify_new_assignments_job = TestTrack::NotifyNewAssignmentsJob.new(
      mixpanel_distinct_id: visitor.id,
      visitor_id: visitor.id,
      new_assignments: visitor.new_assignments
    )
    Delayed::Job.enqueue(notify_new_assignments_job)
  end
end
