# Source vendored gems the hard way in all environments
%w(her fakeable_her public_suffix).each do |gem_name|
  lib = File.expand_path("../../vendor/gems/#{gem_name}/lib", __FILE__)
  $LOAD_PATH.push(lib) unless $LOAD_PATH.include?(lib)
  require gem_name
end

require 'public_suffix'
require 'mixpanel-ruby'
require 'resolv'
require 'faraday_middleware'
require 'request_store'
require 'test_track/unrecoverable_connectivity_error'

module TestTrack
  module_function

  SERVER_ERRORS = [Faraday::ConnectionFailed, Faraday::TimeoutError, Her::Errors::RemoteServerError].freeze
  BUILD_TIMESTAMP_FILE_PATH = 'testtrack/build_timestamp'.freeze
  BUILD_TIMESTAMP_REGEX = /\A\d{4}-[01]\d-[0-3]\dT[0-2]\d:[0-5]\d:[0-5]\d(.\d+)?([+-][0-2]\d:[0-5]\d|Z)\z/

  mattr_accessor :enabled_override, :app_name

  class << self
    def analytics
      analytics_wrapper(analytics_instance || mixpanel)
    end

    def analytics=(*_)
      raise "`TestTrack.analytics=` is not longer supported. Please use `TestTrack.analytics_class_name=` instead."
    end

    def analytics_class_name=(client_class_name)
      begin
        client_class = client_class_name.constantize
        client_class.respond_to?(:instance) || client_class.new
      rescue StandardError
        raise "analytics_class_name #{client_class_name} must be a class that can be instantiated without arguments"
      end
      @analytics_class_name = client_class_name
    end

    def misconfiguration_notifier
      TestTrack::MisconfigurationNotifier::Wrapper.new(misconfiguration_notifier_instance || default_notifier)
    end

    def misconfiguration_notifier_class_name=(notifier_class_name)
      begin
        notifier_class = notifier_class_name.constantize
        notifier_class.respond_to?(:instance) || notifier_class.new
      rescue StandardError
        raise "misconfiguration_notifier_class_name #{notifier_class_name} must be a class that can be instantiated without arguments"
      end
      @misconfiguration_notifier_class_name = notifier_class_name
    end

    def generate_build_timestamp # rubocop:disable Metrics/AbcSize
      if Rails.env.test? || Rails.env.development?
        TestTrack.const_set('BUILD_TIMESTAMP', Time.zone.now.iso8601)
      elsif File.exist?(BUILD_TIMESTAMP_FILE_PATH) && BUILD_TIMESTAMP_REGEX.match?(build_timestamp)
        TestTrack.const_set('BUILD_TIMESTAMP', build_timestamp)
      else
        raise 'TestTrack failed to load the required build timestamp. ' \
          'Ensure `testtrack generate_build_timestamp` is run and the build timestamp file is present.'
      end
    end

    private

    def analytics_instance
      analytics_class = @analytics_class_name&.constantize
      if analytics_class
        analytics_class.respond_to?(:instance) ? analytics_class.instance : analytics_class.new
      end
    end

    def misconfiguration_notifier_instance
      notifier_class = @misconfiguration_notifier_class_name&.constantize
      if notifier_class
        notifier_class.respond_to?(:instance) ? notifier_class.instance : notifier_class.new
      end
    end

    def default_notifier
      if defined?(::Airbrake)
        TestTrack::MisconfigurationNotifier::Airbrake.new
      else
        TestTrack::MisconfigurationNotifier::Null.new
      end
    end

    def analytics_wrapper(client)
      TestTrack::Analytics::SafeWrapper.new(client)
    end

    def mixpanel
      TestTrack::Analytics::MixpanelClient.new
    end

    def app
      TestTrack::ApplicationIdentity.instance
    end
  end

  def update_config
    yield(ConfigUpdater.new)
  end

  def url
    return nil unless private_url

    full_uri = URI.parse(private_url)
    full_uri.user = nil
    full_uri.password = nil
    full_uri.to_s
  end

  def private_url
    ENV['TEST_TRACK_API_URL']
  end

  def build_timestamp
    @build_timestamp ||= File.read(BUILD_TIMESTAMP_FILE_PATH).chomp
  end

  def enabled?
    enabled_override.nil? ? !Rails.env.test? : enabled_override
  end

  def app_ab(split_name, context:)
    app.test_track_ab(split_name, context: context)
  end
end
