require 'delayed_job'
require 'delayed_job_active_record'

class TestTrack::Session
  COOKIE_LIFESPAN = 1.year # Used for mixpanel cookie and tt_visitor_id cookie

  def initialize(controller)
    @controller = controller
  end

  def manage
    yield
  ensure
    manage_cookies!
    notify_new_assignments! if new_assignments?
    create_alias! if signed_up?
  end

  def visitor_dsl
    @visitor_dsl ||= TestTrack::VisitorDSL.new(visitor)
  end

  def state_hash
    {
      url: TestTrack.url,
      cookieDomain: cookie_domain,
      registry: visitor.split_registry,
      assignments: visitor.assignment_registry
    }
  end

  def log_in!(identifier_type, identifier)
    identifier_opts = { identifier_type: identifier_type, visitor_id: visitor.id, value: identifier.to_s }
    begin
      identifier = TestTrack::Remote::Identifier.create!(identifier_opts)
      visitor.merge!(identifier.visitor)
    rescue *TestTrack::SERVER_ERRORS
      # If at first you don't succeed, async it - we may not display 100% consistent UX this time,
      # but subsequent requests will be better off
      TestTrack::Remote::Identifier.delay.create!(identifier_opts)
    end
    true
  end

  def sign_up!(identifier_type, identifier)
    log_in!(identifier_type, identifier)
    @signed_up = true
  end

  private

  attr_reader :controller, :signed_up
  alias_method :signed_up?, :signed_up

  def visitor
    @visitor ||= TestTrack::Visitor.new(id: cookies[:tt_visitor_id])
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
    @cookie_domain ||= _cookie_domain
  end

  def _cookie_domain
    if request.host.match(Resolv::AddressRegex)
      request.host
    else
      "." + PublicSuffix.parse(request.host).domain
    end
  end

  def manage_cookies!
    set_cookie(mixpanel_cookie_name, URI.escape(mixpanel_cookie.to_json))
    set_cookie(:tt_visitor_id, visitor.id)
  end

  def request
    controller.request
  end

  def cookies
    controller.send(:cookies)
  end

  def notify_new_assignments!
    job = TestTrack::NotifyNewAssignmentsJob.new(
      mixpanel_distinct_id: mixpanel_distinct_id,
      visitor_id: visitor.id,
      new_assignments: visitor.new_assignments
    )
    Delayed::Job.enqueue(job)
  end

  def create_alias!
    job = TestTrack::CreateAliasJob.new(
      mixpanel_distinct_id: mixpanel_distinct_id,
      visitor_id: visitor.id
    )
    Delayed::Job.enqueue(job)
  end

  def new_assignments?
    visitor.new_assignments.present?
  end

  def mixpanel_distinct_id
    mixpanel_cookie['distinct_id']
  end

  def mixpanel_cookie
    @mixpanel_cookie ||= read_mixpanel_cookie || generate_mixpanel_cookie
  end

  def read_mixpanel_cookie
    mixpanel_cookie = cookies[mixpanel_cookie_name]
    begin
      JSON.parse(URI.unescape(mixpanel_cookie)) if mixpanel_cookie
    rescue JSON::ParserError
      Rails.logger.error("malformed mixpanel JSON from cookie #{URI.unescape(mixpanel_cookie)}")
      nil
    end
  end

  def generate_mixpanel_cookie
    { 'distinct_id' => visitor.id }
  end

  def mixpanel_token
    ENV['MIXPANEL_TOKEN'] || raise("ENV['MIXPANEL_TOKEN'] must be set")
  end

  def mixpanel_cookie_name
    "mp_#{mixpanel_token}_mixpanel"
  end
end
