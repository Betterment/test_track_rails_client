module TestTrack::Identity
  extend ActiveSupport::Concern

  module ClassMethods
    # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
    def test_track_identifier(identifier_type, identifier_value_method)
      instance_methods = Module.new
      include instance_methods

      instance_methods.module_eval do
        define_method :test_track_ab do |*args|
          discriminator = TestTrack::IdentitySessionDiscriminator.new(self)

          if discriminator.authenticated_resource_matches_identity?
            discriminator.controller.send(:test_track_visitor).ab(*args)
          else
            identifier_value = send(identifier_value_method)
            TestTrack::OfflineSession.with_visitor_for(identifier_type, identifier_value) do |v|
              v.ab(*args)
            end
          end
        end

        define_method :test_track_vary do |*args, &block|
          discriminator = TestTrack::IdentitySessionDiscriminator.new(self)

          if discriminator.authenticated_resource_matches_identity?
            discriminator.controller.send(:test_track_visitor).vary(*args, &block)
          else
            identifier_value = send(identifier_value_method)
            TestTrack::OfflineSession.with_visitor_for(identifier_type, identifier_value) do |v|
              v.vary(*args, &block)
            end
          end
        end

        define_method :test_track_visitor_id do
          discriminator = TestTrack::IdentitySessionDiscriminator.new(self)

          if discriminator.authenticated_resource_matches_identity?
            discriminator.controller.send(:test_track_visitor).id
          else
            identifier_value = send(identifier_value_method)
            TestTrack::OfflineSession.with_visitor_for(identifier_type, identifier_value) do |v|
              v.id
            end
          end
        end

        define_method :test_track_sign_up! do
          discriminator = TestTrack::IdentitySessionDiscriminator.new(self)

          if discriminator.web_context?
            identifier_value = send(identifier_value_method)
            discriminator.controller.send(:test_track_session).sign_up! identifier_type, identifier_value
          else
            raise "test_track_sign_up! called outside of a web context"
          end
        end

        define_method :test_track_log_in! do |opts = {}|
          discriminator = TestTrack::IdentitySessionDiscriminator.new(self)

          if discriminator.web_context?
            identifier_value = send(identifier_value_method)
            discriminator.controller.send(:test_track_session).log_in! identifier_type, identifier_value, opts
          else
            raise "test_track_log_in! called outside of a web context"
          end
        end
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  end
end
