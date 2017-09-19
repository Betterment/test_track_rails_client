class TestTrack::IdentitySessionDiscriminator
  attr_reader :identity

  def initialize(identity)
    @identity = identity
  end

  def with_visitor
    raise ArgumentError, "must provide block to `with_visitor`" unless block_given?

    if matching_identity?
      yield session.visitor_dsl
    else
      TestTrack::OfflineSession.with_visitor_for(identity.test_track_identifier_type, identity.test_track_identifier_value) do |v|
        yield v
      end
    end
  end

  def with_session
    raise ArgumentError, "must provide block to `with_session`" unless block_given?

    if web_context?
      yield session
    else
      raise "#with_session called outside of web context"
    end
  end

  private

  def matching_identity?
    session.present? && session.has_matching_identity?(identity)
  end

  def web_context?
    session.present?
  end

  def session
    @session ||= RequestStore[:test_track_session]
  end
end
