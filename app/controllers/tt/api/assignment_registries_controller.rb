class Tt::Api::AssignmentRegistriesController < ActionController::Base
  def show
    @assignments = TestTrack::FakeTestTrack.assignments
  end
end
