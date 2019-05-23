class TestTrack::IdentitySessionLocator
  attr_reader :identity

  def initialize(identity)
    @identity = identity
  end

  def with_visitor
    raise ArgumentError, "must provide block to `with_visitor`" unless block_given?

    if web_session?
      yield web_session.visitor_dsl_for(identity)
    elsif background_session?
      yield background_session.visitor_dsl_for(identity)
    else
      TestTrack::OfflineSession.with_visitor_for(identity.test_track_identifier_type, identity.test_track_identifier_value) do |v|
        yield v
      end
    end
  end

  def with_session
    raise ArgumentError, "must provide block to `with_session`" unless block_given?

    if web_session?
      yield web_session
    else
      raise "#with_session called outside of web session"
    end
  end

  private

  def web_session?
    web_session.present?
  end

  def web_session
    @web_session ||= RequestStore[:test_track_web_session]
  end

  def background_session?
    background_session.present?
  end

  def background_session
    @background_session ||= RequestStore[:test_track_background_session]
  end
end
