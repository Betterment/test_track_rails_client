class TestTrack::IdentitySessionDiscriminator
  attr_reader :identity

  def initialize(identity)
    @identity = identity
  end

  def controller
    @controller ||= RequestStore[:test_track_controller]
  end

  def participate_in_online_session?
    web_context? && controller_has_authenticated_resource? && authenticated_resource_matches_identity?
  end

  private

  def authenticated_resource_matches_identity?
    controller.send(authenticated_resource_method_name) == identity
  end

  def controller_has_authenticated_resource?
    controller.respond_to?(authenticated_resource_method_name)
  end

  def web_context?
    controller.present?
  end

  def authenticated_resource_method_name
    @authenticated_resource_method_name ||= "current_#{identity.class.name.downcase}"
  end
end
