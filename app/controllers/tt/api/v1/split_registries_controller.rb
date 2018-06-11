class Tt::Api::V1::SplitRegistriesController < Tt::Api::ApplicationController
  def show
    @active_splits = TestTrack::FakeServer.split_registry
  end
end
