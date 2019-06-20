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

  mattr_accessor :enabled_override, :app_name

  class << self
    def analytics
      @analytics ||= analytics_wrapper(mixpanel)
    end

    def analytics=(client)
      @analytics = client.is_a?(TestTrack::Analytics::SafeWrapper) ? client : analytics_wrapper(client)
    end

    def misconfiguration_notifier
      @misconfiguration_notifier ||= TestTrack::MisconfigurationNotifier::Wrapper.new(default_notifier)
    end

    def misconfiguration_notifier=(notifier)
      @misconfiguration_notifier = if notifier.is_a?(TestTrack::MisconfigurationNotifier::Wrapper)
                                     notifier
                                   else
                                     TestTrack::MisconfigurationNotifier::Wrapper.new(notifier)
                                   end
    end

    private

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

  def enabled?
    enabled_override.nil? ? !Rails.env.test? : enabled_override
  end

  def app_ab(split_name, context:)
    app.test_track_ab(split_name, context: context)
  end
end
