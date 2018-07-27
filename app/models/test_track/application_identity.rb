class TestTrack::ApplicationIdentity
  include Singleton
  include TestTrack::Identity

  test_track_identifier :app_id, :app_name

  private

  def app_name
    raise 'must configure TestTrack.app_name on application initialization' if TestTrack.app_name.blank?
    TestTrack.app_name
  end
end
