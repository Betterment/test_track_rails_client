class TestTrack::IdentitySessionDiscriminator
  attr_reader :identity

  def initialize(identity)
    @identity = identity
  end

  def controller
    @controller ||= RequestStore[:test_track_controller]
  end

  def participate_in_online_session?
    authenticated_resource_matches_identity?
  end

  def participate_in_unauthenticated_session?
    web_context? && !controller.respond_to?(authenticated_resource_method_name, true)
  end

  private

  def authenticated_resource_matches_identity?
    controller_has_authenticated_resource? && controller.send(authenticated_resource_method_name) == identity
  end

  def controller_has_authenticated_resource?
    # pass true to `respond_to?` to include private methods
    web_context? && controller.respond_to?(authenticated_resource_method_name, true)
  end

  def web_context?
    controller.present?
  end

  def authenticated_resource_method_name
    @authenticated_resource_method_name ||= "current_#{identity.class.model_name.element}"
  end
end
