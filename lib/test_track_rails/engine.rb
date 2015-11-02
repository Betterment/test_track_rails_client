require 'airbrake'
require 'delayed_job'
require 'delayed-plugins-airbrake'

module TestTrackRails
  class Engine < ::Rails::Engine
    isolate_namespace TestTrackRails

    initializer 'test_track_rails.errbit_config' do
      config = Airbrake.configuration
      puts "[test_track_rails] errbit #{config.api_key}@#{config.host}:#{config.port}" # rubocop:disable Rails/Output
    end

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
