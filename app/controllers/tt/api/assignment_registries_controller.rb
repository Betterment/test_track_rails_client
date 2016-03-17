class Tt::Api::AssignmentRegistriesController < ActionController::Base
  def show
    @splits = TestTrack::FakeServer.assignments
  end
end
