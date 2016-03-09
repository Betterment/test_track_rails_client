class Tt::Api::IdentifiersController < ActionController::Base
  def create
    @visitor = TestTrack::FakeTestTrack.visitor
  end
end
