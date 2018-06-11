class Tt::Api::V1::IdentifierVisitorsController < Tt::Api::ApplicationController
  def show
    @visitor = TestTrack::FakeServer.visitor
  end
end
