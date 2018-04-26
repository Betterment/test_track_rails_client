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
          locator = TestTrack::IdentitySessionLocator.new(self)
          locator.with_visitor do |v|
            v.ab(*args)
          end
        end

        define_method :test_track_vary do |*args, &block|
          locator = TestTrack::IdentitySessionLocator.new(self)
          locator.with_visitor do |v|
            v.vary(*args, &block)
          end
        end

        define_method :test_track_visitor_id do
          locator = TestTrack::IdentitySessionLocator.new(self)
          locator.with_visitor do |v|
            v.id
          end
        end

        define_method :test_track_sign_up! do
          locator = TestTrack::IdentitySessionLocator.new(self)
          locator.with_session do |session|
            session.sign_up! self
          end
        end

        define_method :test_track_log_in! do |opts = {}|
          locator = TestTrack::IdentitySessionLocator.new(self)
          locator.with_session do |session|
            session.log_in! self, opts
          end
        end
      end
    end
  end
end
