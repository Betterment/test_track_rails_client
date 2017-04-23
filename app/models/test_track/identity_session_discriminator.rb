class TestTrack::IdentitySessionDiscriminator
  attr_reader :identity

  def initialize(identity)
    @identity = identity
  end

  def controller
    @controller ||= RequestStore[:test_track_controller]
  end

  def authenticated_resource_matches_identity?
    controller_has_authenticated_resource? && controller.send(authenticated_resource_method_name) == identity
  end

  def web_context?
    controller.present? && !controller.test_track_web_context_disabled?
  end

  private

  def controller_has_authenticated_resource?
    # pass true to `respond_to?` to include private methods
    web_context? && controller.respond_to?(authenticated_resource_method_name, true)
  end

  def authenticated_resource_method_name
    @authenticated_resource_method_name ||= "current_#{identity.class.model_name.element}"
  end
end
