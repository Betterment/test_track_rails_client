module TestTrack::RemoteModel
  extend ActiveSupport::Concern
  include FakeableHer::Model

  included do
    use_api TestTrack::TestTrackApi
  end

  module ClassMethods
    def faked?
      !TestTrack.enabled?
    end
  end
end
