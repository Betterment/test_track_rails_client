class Tt::Api::IdentifierVisitorsController < ActionController::Base
  def show
    @visitor = TestTrack::FakeTestTrack.visitor
  end
end
