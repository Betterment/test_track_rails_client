class Tt::Api::VisitorsController < Tt::Api::ApplicationController
  def show
    @visitor = TestTrack::FakeServer.visitor
  end
end
