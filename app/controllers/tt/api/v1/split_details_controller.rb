class Tt::Api::V1::SplitDetailsController < Tt::Api::V1::ApplicationController
  def show
    @split_detail = TestTrack::FakeServer.split_details
  end
end
