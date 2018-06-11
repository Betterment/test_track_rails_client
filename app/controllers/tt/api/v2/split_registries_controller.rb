class Tt::Api::V2::SplitRegistriesController < Tt::Api::ApplicationController
  def show
    @active_splits = TestTrack::FakeServer.split_registry
  end
end
