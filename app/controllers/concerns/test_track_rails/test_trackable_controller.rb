module TestTrackRails
  module TestTrackableController
    extend ActiveSupport::Concern

    included do
      attr_reader :tt_visitor_id
      helper_method :tt_visitor_id, :tt_cookie_domain, :tt_split_registry, :tt_assignment_registry

      before_action :initialize_test_track
    end

    def tt_cookie_domain
      @tt_cookie_domain ||= TestTrackRails.cookie_domain(request.host)
    end

    def tt_assignment_registry
      @tt_assignment_registry ||= TestTrackRails::AssignmentRegistry.for_visitor(tt_visitor_id).attributes
    end

    private

    def initialize_test_track
      read_test_track_visitor_id || generate_test_track_visitor_id
      cookies.permanent[:tt_visitor_id] = {
        value: tt_visitor_id,
        domain: tt_cookie_domain,
        secure: request.ssl?,
        httponly: false
      }
    end

    def read_test_track_visitor_id
      @tt_visitor_id = cookies[:tt_visitor_id]
    end

    def generate_test_track_visitor_id
      @tt_visitor_id = SecureRandom.uuid
      @tt_assignment_registry = {} # Generated visitors don't need to query the server for assignments
    end
  end
end
