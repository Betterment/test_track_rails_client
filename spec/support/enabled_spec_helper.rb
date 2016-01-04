module EnabledSpecHelper
  def with_test_track_enabled
    TestTrack.enabled = true
    yield
  ensure
    TestTrack.enabled = false
  end
end
