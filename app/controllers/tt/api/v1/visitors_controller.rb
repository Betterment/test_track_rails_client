class Tt::Api::V1::VisitorsController < Tt::Api::ApplicationController
  def show
    @visitor = TestTrack::FakeServer.visitor
  end
end
