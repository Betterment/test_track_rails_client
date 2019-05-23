require 'delayed_job'
require 'delayed_job_active_record'

class TestTrack::Session
  COOKIE_LIFESPAN = 1.year # Used for visitor cookie

  def initialize(controller)
    @controller = controller
  end

  def manage
    yield
  ensure
    if current_visitor.id_loaded?
      manage_cookies!
      manage_response_headers!
    end
    visitors.notify_unsynced_assignments!
  end

  def visitor_dsl_for(identity)
    TestTrack::VisitorDSL.new(visitors.for_identity(identity))
  end

  def visitor_dsl
    TestTrack::VisitorDSL.new(current_visitor)
  end

  def state_hash
    {
      url: TestTrack.url,
      cookieDomain: cookie_domain,
      cookieName: visitor_cookie_name,
      registry: current_visitor.split_registry.to_v1_hash,
      assignments: current_visitor.assignment_json
    }
  end

  def log_in!(identity, forget_current_visitor: nil)
    visitors.forget_unauthenticated! if forget_current_visitor
    visitors.authenticate!(identity)
    true
  end

  def sign_up!(identity)
    visitors.authenticate!(identity)
    TestTrack.analytics.sign_up!(current_visitor.id)
    true
  end

  private

  attr_reader :controller

  def current_identity
    raise <<~ERROR unless controller.class.test_track_identity&.is_a?(Symbol)
      Your controller (or controller base class) must set test_track_identity for
      TestTrack to work properly. e.g.:

        self.test_track_identity = :current_user

      If your app doesn't support authentication, set it to `:none`.
    ERROR
    identity = controller.class.test_track_identity
    controller.send(identity) unless identity == :none
  end

  def unauthenticated_visitor_id
    cookies[visitor_cookie_name] || request_headers[visitor_request_header_name]
  end

  def visitors
    @visitors ||= TestTrack::SessionVisitorRepository.new(
      current_identity: current_identity,
      unauthenticated_visitor_id: unauthenticated_visitor_id
    )
  end

  def current_visitor
    visitors.current
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
    if bare_ip_address? || fully_qualified_cookie_domain_enabled?
      request.host
    else
      wildcard_domain
    end
  end

  def bare_ip_address?
    request.host.match(Resolv::AddressRegex)
  end

  def wildcard_domain
    "." + (public_suffix_domain || request.host)
  end

  def public_suffix_domain
    @public_suffix_domain ||= PublicSuffix.domain(request.host, default_rule: nil)
  end

  def manage_cookies!
    set_cookie(visitor_cookie_name, current_visitor.id)
  end

  def request
    controller.request
  end

  def response
    controller.response
  end

  def cookies
    controller.send(:cookies)
  end

  def request_headers
    request.headers
  end

  def response_headers
    response.headers
  end

  def manage_response_headers!
    response_headers[visitor_response_header_name] = current_visitor.id if current_visitor.id_overridden_by_existing_visitor?
  end

  def visitor_cookie_name
    ENV['TEST_TRACK_VISITOR_COOKIE_NAME'] || 'tt_visitor_id'
  end

  def visitor_request_header_name
    ENV['TEST_TRACK_VISITOR_REQUEST_HEADER_NAME'] || 'X-TT-Visitor-ID'
  end

  def visitor_response_header_name
    ENV['TEST_TRACK_VISITOR_RESPONSE_HEADER_NAME'] || 'X-Set-TT-Visitor-ID'
  end

  def fully_qualified_cookie_domain_enabled?
    ENV['TEST_TRACK_FULLY_QUALIFIED_COOKIE_DOMAIN_ENABLED'] == '1'
  end
end
