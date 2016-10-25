class Tt::Api::V1::VisitorsController < Tt::Api::V1::ApplicationController
  def show
    @visitor = TestTrack::FakeServer.visitor
  end
end
