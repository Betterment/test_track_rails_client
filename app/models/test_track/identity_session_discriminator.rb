class TestTrack::IdentitySessionDiscriminator
  attr_reader :identity

  def initialize(identity)
    @identity = identity
  end

  def with_visitor
    if authenticated_resource_matches_identity?
      yield controller.send(:test_track_visitor)
    else
      TestTrack::OfflineSession.with_visitor_for(identity.test_track_identifier_type, identity.test_track_identifier_value) do |v|
        yield v
      end
    end
  end

  def with_session
    if web_context?
      yield controller.send(:test_track_session)
    else
      raise "with_session called outside of a web context"
    end
  end

  private

  def authenticated_resource_matches_identity?
    web_session.authenticated_resource_matches_identity?(identity)
  end

  def web_context?
    web_session.present?
  end

  def web_session
    @web_session ||= RequestStore[:test_track_web_session]
  end
end
