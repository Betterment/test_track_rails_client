module TestTrack::RemoteModel
  extend ActiveSupport::Concern
  include FakeableHer::Model

  included do
    use_api TestTrack::TestTrackApi
  end

  module ClassMethods
    def service_name
      :test_track
    end
  end
end
