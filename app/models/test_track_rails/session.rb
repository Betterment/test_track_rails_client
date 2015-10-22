require 'delayed_job'
require 'delayed_job_active_record'

module TestTrackRails
  class Session
    COOKIE_LIFESPAN = 1.year # Used for mixpanel cookie and tt_visitor_id cookie

    attr_reader :mixpanel_distinct_id

    def initialize(controller)
      @controller = controller
    end

    def manage
      manage_cookies!
      yield
    ensure
      flush_events!
    end

    def visitor
      @visitor ||= Visitor.new(id: cookies[:tt_visitor_id])
    end

    def set_cookie(name, value)
      cookies[name] = {
        value: value,
        domain: cookie_domain,
        secure: request.ssl?,
        httponly: false,
        expires: COOKIE_LIFESPAN.from_now
      }
    end

    def cookie_domain
      @cookie_domian ||= "." + PublicSuffix.parse(request.host).domain
    end

    private

    attr_reader :controller

    def manage_cookies!
      read_mixpanel_distinct_id || generate_mixpanel_distinct_id
      set_cookie(:tt_visitor_id, visitor_id)
    end

    def visitor_id
      visitor.id
    end

    def request
      controller.request
    end

    def cookies
      controller.send(:cookies)
    end

    def flush_events!
      return unless visitor.new_assignments.present?
      job = NotificationJob.new(
        mixpanel_distinct_id: mixpanel_distinct_id,
        visitor_id: visitor.id,
        new_assignments: visitor.new_assignments
      )
      Delayed::Job.enqueue(job)
    end

    def read_mixpanel_distinct_id
      mixpanel_cookie = cookies[mixpanel_cookie_name]
      @mixpanel_distinct_id = JSON.parse(URI.unescape(mixpanel_cookie))['distinct_id'] if mixpanel_cookie
    end

    def generate_mixpanel_distinct_id
      set_cookie(mixpanel_cookie_name, URI.escape({ distinct_id: visitor_id }.to_json))
      @mixpanel_distinct_id = visitor_id
    end

    def mixpanel_token
      ENV['MIXPANEL_TOKEN'] || raise("ENV['MIXPANEL_TOKEN'] must be set")
    end

    def mixpanel_cookie_name
      "mp_#{mixpanel_token}_mixpanel"
    end
  end
end
