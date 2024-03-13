require 'active_job'
require 'active_model'
require 'test_track'

module TestTrackRailsClient
  class Engine < ::Rails::Engine
    isolate_namespace TestTrack

    config.generators do |g|
      g.test_framework :rspec
    end

    initializer after: 'active_support.initialize_time_zone' do
      TestTrack.set_build_timestamp! unless ENV['SKIP_TESTTRACK_SET_BUILD_TIMESTAMP'] == '1'
    end
  end
end
