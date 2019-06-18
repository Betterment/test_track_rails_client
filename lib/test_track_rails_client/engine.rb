require 'delayed_job'

begin
  require 'airbrake'
rescue LoadError
end

unless defined?(Delayed::Plugins::Airbrake) && Delayed::Worker.plugins.include?(Delayed::Plugins::Airbrake)
  begin
    require 'delayed-plugins-airbrake'
  rescue LoadError
  end
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
