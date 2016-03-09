class Tt::Api::VisitorsController < ActionController::Base
  def show
    @visitor = TestTrack::FakeTestTrack.visitor
  end
end
