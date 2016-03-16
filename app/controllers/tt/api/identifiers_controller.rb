class Tt::Api::IdentifiersController < ActionController::Base
  def create
    @visitor = TestTrack::FakeServer.visitor
  end
end
