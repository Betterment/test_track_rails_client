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
    notify_unsynced_assignments! if sync_assignments?
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
      registry: current_visitor.split_registry,
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
    if bare_ip_address?
      request.host
    elsif fully_qualified_cookie_domain_enabled?
      fully_qualified_domain
    else
      wildcard_domain
    end
  end

  def bare_ip_address?
    request.host.match(Resolv::AddressRegex)
  end

  def fully_qualified_domain
    public_suffix_host.name
  end

  def wildcard_domain
    "." + public_suffix_host.domain
  end

  def public_suffix_host
    @public_suffix_host ||= PublicSuffix.parse(request.host, default_rule: nil)
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

  def notify_unsynced_assignments!
    payload = {
      visitor_id: current_visitor.id,
      assignments: current_visitor.unsynced_assignments
    }
    ActiveSupport::Notifications.instrument('test_track.notify_unsynced_assignments', payload) do
      ##
      # This block creates an unbounded number of threads up to 1 per request.
      # This can potentially cause issues under high load, in which case we should move to a thread pool/work queue.
      new_thread_with_request_store do
        TestTrack::UnsyncedAssignmentsNotifier.new(payload).notify
      end
    end
  end

  def sync_assignments?
    current_visitor.loaded? && current_visitor.unsynced_assignments.present?
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

  def new_thread_with_request_store
    Thread.new(RequestStore.store) do |original_store|
      begin
        RequestStore.begin!
        RequestStore.store.merge!(original_store)
        yield
      ensure
        RequestStore.end!
        RequestStore.clear!
      end
    end
  end
end
