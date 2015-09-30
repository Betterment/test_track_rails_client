module TestTrackRails
  class Engine < ::Rails::Engine
    isolate_namespace TestTrackRails

    config.generators do |g|
      g.test_framework :rspec
    end
  end
end
