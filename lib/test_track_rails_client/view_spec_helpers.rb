module TestTrackRailsClient::ViewSpecHelpers
  def self.install!(identity: :none)
    require 'action_view/test_case'

    ActionView::TestCase::TestController.class_eval do
      include TestTrack::Controller unless include?(TestTrack::Controller)
      self.test_track_identity = identity

      define_method(identity) { nil } unless identity == :none || method_defined?(identity)
    end
  end
end
