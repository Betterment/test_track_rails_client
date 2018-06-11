class Tt::Api::V1::SplitDetailsController < Tt::Api::ApplicationController
  def show
    @split_detail = TestTrack::FakeServer.split_details(params[:id])
  end
end
