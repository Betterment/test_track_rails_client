class TestTrack::IdentitySessionDiscriminator
  attr_reader :identity

  def initialize(identity)
    @identity = identity
  end

  def with_visitor
    if managed_identity?
      yield session.visitor_dsl
    else
      TestTrack::OfflineSession.with_visitor_for(identity.test_track_identifier_type, identity.test_track_identifier_value) do |v|
        yield v
      end
    end
  end

  def with_session
    if web_context?
      yield session
    else
      raise "#with_session called outside of web context"
    end
  end

  private

  def managed_identity?
    session.managed_identity?(identity)
  end

  def web_context?
    session.present?
  end

  def session
    @session ||= RequestStore[:test_track_session]
  end
end
