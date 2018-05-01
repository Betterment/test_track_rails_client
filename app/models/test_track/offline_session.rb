class TestTrack::OfflineSession
  AnalyticsAssignment = Struct.new(:visitor_id, :split_name, :variant, :context, :unsynced) do
    def unsynced?
      unsynced
    end

    def feature_gate?
      split_name.end_with?('_enabled')
    end
  end

  def initialize(remote_visitor)
    @remote_visitor = remote_visitor
  end

  def self.with_visitor_for(identifier_type, identifier_value)
    raise ArgumentError, "must provide block to `with_visitor_for`" unless block_given?

    remote_visitor = TestTrack::Remote::Visitor.from_identifier(identifier_type, identifier_value)

    new(remote_visitor).send :manage do |visitor_dsl|
      yield visitor_dsl
    end
  end

  def self.with_visitor_id(visitor_id)
    raise ArgumentError, "must provide block to `with_visitor_id`" unless block_given?

    remote_visitor = TestTrack::Remote::Visitor.find(visitor_id)

    new(remote_visitor).send :manage do |visitor_dsl|
      yield visitor_dsl
    end
  end

  private

  attr_reader :remote_visitor

  def visitor
    @visitor ||= TestTrack::Visitor.new(
      id: remote_visitor.id,
      assignments: analytics_assignments
    )
  end

  def analytics_assignments
    remote_visitor.assignments.map do |remote_assignment|
      AnalyticsAssignment.new(
        remote_visitor.id,
        remote_assignment.split_name,
        remote_assignment.variant,
        remote_assignment.context,
        remote_assignment.unsynced
      )
    end
  end

  def manage
    yield TestTrack::VisitorDSL.new(visitor)
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
