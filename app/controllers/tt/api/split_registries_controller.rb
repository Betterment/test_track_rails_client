class Tt::Api::SplitRegistriesController < ActionController::Base
  def show
    @active_splits = TestTrack::FakeTestTrack.split_registry
  end
end
