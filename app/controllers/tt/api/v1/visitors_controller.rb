class Tt::Api::V1::VisitorsController < Tt::Api::V1::ApplicationController
  def show
    @visitor = TestTrack::FakeServer.visitor_by_id(params[:id])
  end
end
