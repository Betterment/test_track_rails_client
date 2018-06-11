class Tt::Api::V1::IdentifiersController < Tt::Api::ApplicationController
  def create
    @visitor = TestTrack::FakeServer.visitor
  end
end
