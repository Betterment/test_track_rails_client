class Tt::Api::V1::IdentifierVisitorsController < Tt::Api::V1::ApplicationController
  def show
    @visitor = TestTrack::FakeServer.visitor
  end
end
