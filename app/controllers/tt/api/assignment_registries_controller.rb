class Tt::Api::AssignmentRegistriesController < Tt::Api::ApplicationController
  def show
    @assignments = TestTrack::FakeServer.assignments
  end
end
