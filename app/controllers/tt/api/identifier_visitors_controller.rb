class Tt::Api::IdentifierVisitorsController < ActionController::Base
  def show
    @visitor = TestTrack::FakeServer.visitor
  end
end
