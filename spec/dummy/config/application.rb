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

    if rails_version_between?('5.1', '5.2')
      config.load_defaults 5.1
    elsif rails_version_between?('5.2', '6.0')
      config.load_defaults 5.2
    elsif rails_version_between?('6.0', '6.1')
      config.load_defaults 6.0
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    config.active_record.sqlite3&.represent_boolean_as_integer = true
  end
end
