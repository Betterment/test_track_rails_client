class Tt::Api::AssignmentRegistriesController < ActionController::Base
  def show
    @assignments = TestTrack::FakeServer.assignments
  end
end
