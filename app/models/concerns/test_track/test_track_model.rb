module TestTrack
  module TestTrackModel
    extend ActiveSupport::Concern
    include FakeableHer::Model

    included do
      use_api TestTrackApi
    end

    module ClassMethods
      def service_name
        :test_track
      end
    end
  end
end
