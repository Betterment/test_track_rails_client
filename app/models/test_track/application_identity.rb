class TestTrack::ApplicationIdentity
  include Singleton

  delegate :test_track_ab, to: :identity

  private

  def app_name
    raise 'must configure TestTrack.app_name on application initialization' if TestTrack.app_name.blank?

    TestTrack.app_name
  end

  def identity
    Identity.new(app_name)
  end

  class Identity
    include TestTrack::Identity

    test_track_identifier :app_id, :app_name

    def initialize(app_name)
      @app_name = app_name
    end

    private

    attr_reader :app_name
  end

  private_constant :Identity
end
