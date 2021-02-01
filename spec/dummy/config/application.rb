require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)
require "test_track_rails_client"

module Dummy
  class Application < Rails::Application
    def rails_version_between?(version_1, version_2)
      Rails.gem_version.between?(
        Gem::Version.new(version_1),
        Gem::Version.new(version_2),
      )
    end

    config.load_defaults 5.1 if rails_version_between?('5.1', '5.2')
    config.load_defaults 5.2 if rails_version_between?('5.2', '6.0')
    config.load_defaults 6.0 if rails_version_between?('6.0', '6.1')
    config.load_defaults 6.1 if rails_version_between?('6.1', '6.2')
  end
end
