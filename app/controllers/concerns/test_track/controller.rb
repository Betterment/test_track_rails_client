module TestTrack::Controller
  extend ActiveSupport::Concern

  included do
    class_attribute :test_track_identity

    helper_method :test_track_session, :test_track_visitor
    helper TestTrack::ApplicationHelper
    around_action :manage_test_track_session
  end

  class_methods do
    def require_feature_flag(feature_flag, *args, required_variant: nil, **kwargs)
      before_action(*args, **kwargs) do
        raise ActionController::RoutingError, 'Not Found' unless test_track_visitor.ab(feature_flag, true_variant: required_variant,
                                                                                                     context: self.class.name.underscore)
      end
    end
  end

  private

  def test_track_session
    @test_track_session ||= TestTrack::WebSession.new(self)
  end

  def test_track_visitor
    test_track_session.visitor_dsl
  end

  def manage_test_track_session(&block)
    RequestStore[:test_track_web_session] = test_track_session
    test_track_session.manage(&block)
  end
end
