require "test_track_rails/engine"

module TestTrackRails
  module_function

  def update_config
    yield(ConfigUpdater.new)
  end
end
