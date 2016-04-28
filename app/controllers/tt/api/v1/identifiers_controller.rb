class Tt::Api::V1::IdentifiersController < Tt::Api::V1::ApplicationController
  def create
    @visitor = TestTrack::FakeServer.visitor
  end
end
