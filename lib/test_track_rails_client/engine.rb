require 'delayed_job'
require 'airbrake'
unless defined?(Delayed::Plugins::Airbrake) && Delayed::Worker.plugins.include?(Delayed::Plugins::Airbrake)
  require 'delayed-plugins-airbrake'
end
require 'test_track'

module TestTrackRailsClient
  class Engine < ::Rails::Engine
    isolate_namespace TestTrack

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
