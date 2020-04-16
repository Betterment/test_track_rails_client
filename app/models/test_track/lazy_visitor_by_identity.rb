class TestTrack::LazyVisitorByIdentity
  def initialize(identity)
    @identity = identity
  end

  def loaded?
    @__visitor__.present?
  end

  def id_loaded?
    loaded?
  end

  private

  def method_missing(method, *args, &block)
    if __visitor__.respond_to?(method)
      __visitor__.send(method, *args, &block)
    else
      super
    end
  end

  def respond_to_missing?(method, include_private = false)
    super || __visitor__.respond_to?(method, include_private)
  end

  def __visitor__
    @__visitor__ ||= __load_visitor__
  end

  def __load_visitor__
    remote_visitor = TestTrack::Remote::Visitor.from_identifier(
      @identity.test_track_identifier_type,
      @identity.test_track_identifier_value
    )
    TestTrack::Visitor.new(
      id: remote_visitor.id,
      assignments: remote_visitor.assignments
    )
  end
end
