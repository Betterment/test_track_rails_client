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

          if discriminator.participate_in_online_session?
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

          if discriminator.participate_in_online_session?
            discriminator.controller.send(:test_track_visitor).vary(*args, &block)
          else
            identifier_value = send(identifier_value_method)
            TestTrack::OfflineSession.with_visitor_for(identifier_type, identifier_value) do |v|
              v.vary(*args, &block)
            end
          end
        end

        define_method :test_track_identifier do
          discriminator = TestTrack::IdentitySessionDiscriminator.new(self)

          if discriminator.participate_in_online_session?
            discriminator.controller.send(:test_track_visitor).identifier
          else
            identifier_value = send(identifier_value_method)
            TestTrack::OfflineSession.with_visitor_for(identifier_type, identifier_value) do |v|
              v.id
            end
          end
        end
      end
    end
    # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
  end
end
