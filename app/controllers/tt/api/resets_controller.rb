class Tt::Api::ResetsController < Tt::Api::ApplicationController
  def update
    TestTrack::FakeServer.reset!(seed)
    head :no_content
  end

  private

  def seed
    params.permit(:seed)[:seed]
  end
end
