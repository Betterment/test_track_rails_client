require 'airbrake'
require 'delayed_job'
require 'delayed-plugins-airbrake'

module TestTrackRailsClient
  class Engine < ::Rails::Engine
    isolate_namespace TestTrack

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
