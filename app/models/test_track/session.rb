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
    manage_cookies!
    manage_response_headers!
    notify_unsynced_assignments! if sync_assignments?
  end

  def visitor_dsl_for(identity)
    if has_matching_identity?(identity)
      visitor_dsl
    else
      TestTrack::VisitorDSL.new(visitors_by_identity[identity])
    end
  end

  def visitors_by_identity
    @visitors_by_identity ||= Hash.new do |visitors_by_identity, identity|
      remote_visitor = TestTrack::Remote::Visitor.from_identifier(
        identity.test_track_identifier_type,
        identity.test_track_identifier_value
      )
      visitors_by_identity[identity] = TestTrack::Visitor.new(
        id: remote_visitor.id,
        assignments: remote_visitor.assignments
      )
    end
  end

  def visitor_dsl
    @visitor_dsl ||= TestTrack::VisitorDSL.new(visitor)
  end

  def state_hash
    {
      url: TestTrack.url,
      cookieDomain: cookie_domain,
      cookieName: visitor_cookie_name,
      registry: visitor.split_registry,
      assignments: visitor.assignment_json
    }
  end

  def log_in!(identity, forget_current_visitor: nil)
    identifier_type = identity.test_track_identifier_type
    identifier_value = identity.test_track_identifier_value

    @visitor = TestTrack::Visitor.new if forget_current_visitor
    visitor.link_identifier!(identifier_type, identifier_value)

    identities << identity if identity.present?
    true
  end

  def sign_up!(identity)
    identifier_type = identity.test_track_identifier_type
    identifier_value = identity.test_track_identifier_value

    visitor.link_identifier!(identifier_type, identifier_value)
    identities << identity if identity.present?

    TestTrack.analytics.sign_up!(visitor.id)

    true
  end

  def has_matching_identity?(identity)
    identities.include?(identity)
  end

  private

  attr_reader :controller

  def visitor
    @visitor ||= TestTrack::Visitor.new(id: visitor_id)
  end

  def visitor_id
    cookies[visitor_cookie_name] || request_headers[visitor_request_header_name]
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
    set_cookie(visitor_cookie_name, visitor.id)
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
    response_headers[visitor_response_header_name] = visitor.id if visitor.id_overridden_by_existing_visitor?
  end

  def notify_unsynced_assignments!
    payload = {
      visitor_id: visitor.id,
      assignments: visitor.unsynced_assignments
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
    visitor.loaded? && visitor.unsynced_assignments.present?
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

  def identities
    @identities ||= TestTrack::SessionIdentityCollection.new(controller)
  end
end
