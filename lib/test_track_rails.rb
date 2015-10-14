require "test_track_rails/engine"
require 'public_suffix'

module TestTrackRails
  module_function

  def update_config
    yield(ConfigUpdater.new)
  end

  def cookie_domain(host)
    "." + PublicSuffix.parse(host).domain
  end
end
