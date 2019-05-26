module TestTrack::Controller
  extend ActiveSupport::Concern

  included do
    class_attribute :test_track_identity

    helper_method :test_track_session, :test_track_visitor
    helper TestTrack::ApplicationHelper
    around_action :manage_test_track_web_session
  end

  class_methods do
    def require_feature_flag(feature_flag, *args)
      before_action(*args) do
        unless test_track_visitor.ab(feature_flag, context: self.class.name.underscore)
          raise ActionController::RoutingError, 'Not Found'
        end
      end
    end
  end

  private

  def test_track_web_session
    @test_track_web_session ||= TestTrack::WebSession.new(self)
  end

  def test_track_visitor
    test_track_web_session.visitor_dsl
  end

  def manage_test_track_web_session
    RequestStore[:test_track_web_session] = test_track_web_session
    test_track_web_session.manage do
      yield
    end
  end
end
