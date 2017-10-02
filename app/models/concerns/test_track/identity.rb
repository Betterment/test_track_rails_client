module TestTrack::Identity
  extend ActiveSupport::Concern

  module ClassMethods
    def test_track_identifier(identifier_type, identifier_value_method) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      instance_methods = Module.new
      include instance_methods

      instance_methods.module_eval do
        define_method :test_track_identifier_type do
          identifier_type
        end

        define_method :test_track_identifier_value do
          send(identifier_value_method)
        end

        define_method :test_track_ab do |*args|
          discriminator = TestTrack::IdentitySessionDiscriminator.new(self)
          discriminator.with_visitor do |v|
            v.ab(*args)
          end
        end

        define_method :test_track_vary do |*args, &block|
          discriminator = TestTrack::IdentitySessionDiscriminator.new(self)
          discriminator.with_visitor do |v|
            v.vary(*args, &block)
          end
        end

        define_method :test_track_visitor_id do
          discriminator = TestTrack::IdentitySessionDiscriminator.new(self)
          discriminator.with_visitor do |v|
            v.id
          end
        end

        define_method :test_track_sign_up! do
          discriminator = TestTrack::IdentitySessionDiscriminator.new(self)
          discriminator.with_session do |session|
            session.sign_up! self
          end
        end

        define_method :test_track_log_in! do |opts = {}|
          discriminator = TestTrack::IdentitySessionDiscriminator.new(self)
          discriminator.with_session do |session|
            session.log_in! self, opts
          end
        end
      end
    end
  end
end
