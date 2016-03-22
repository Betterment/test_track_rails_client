class Tt::Api::IdentifiersController < Tt::Api::ApplicationController
  def create
    @visitor = TestTrack::FakeServer.visitor
  end
end
