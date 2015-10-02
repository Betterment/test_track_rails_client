require "test_track_rails/engine"
require 'public_suffix'

module TestTrackRails
  module_function

  def update_config
    yield(ConfigUpdater.new)
  end

  def cookie_domain(default = nil)
    "*." + PublicSuffix.parse(host || default).domain
  end

  def default_url_options
    Rails.application.config.action_mailer.default_url_options
  end

  def host
    default_url_options && default_url_options[:host]
  end
end
