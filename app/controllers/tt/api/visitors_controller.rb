class Tt::Api::VisitorsController < ActionController::Base
  def show
    @visitor = TestTrack::FakeServer.visitor
  end
end
