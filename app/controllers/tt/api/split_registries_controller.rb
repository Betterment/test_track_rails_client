class Tt::Api::SplitRegistriesController < ActionController::Base
  def show
    @active_splits = TestTrack::FakeServer.split_registry
  end
end
