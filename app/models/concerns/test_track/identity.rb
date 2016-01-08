module TestTrack::Identity
  extend ActiveSupport::Concern

  module OnlineSessionInformant
    module_function

    def online_session_available?(controller, identity)
      if controller.present?
        authenticated_model_method_name = "current_#{identity.class.name.downcase}"
        if controller.respond_to?(authenticated_model_method_name)
          controller.send(authenticated_model_method_name) == identity
        else
          true
        end
      else
        false
      end
    end
  end

  module ClassMethods
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def test_track_identifier(identifier_type, identifier_value_method)
      instance_methods = Module.new
      include instance_methods

      instance_methods.module_eval do
        define_method :test_track_ab do |*args|
          controller = RequestStore[:test_track_controller]

          if OnlineSessionInformant.online_session_available?(controller, self)
            controller.send(:test_track_visitor).ab(*args)
          else
            identifier_value = send(identifier_value_method)
            TestTrack::OfflineSession.with_visitor_for(identifier_type, identifier_value) do |v|
              v.ab(*args)
            end
          end
        end

        define_method :test_track_vary do |*args, &block|
          controller = RequestStore[:test_track_controller]

          if OnlineSessionInformant.online_session_available?(controller, self)
            controller.send(:test_track_visitor).vary(*args, &block)
          else
            identifier_value = send(identifier_value_method)
            TestTrack::OfflineSession.with_visitor_for(identifier_type, identifier_value) do |v|
              v.vary(*args, &block)
            end
          end
        end
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  end
end
