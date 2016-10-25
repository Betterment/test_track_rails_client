module EnabledSpecHelper
  def with_test_track_enabled
    previous_value = TestTrack.enabled_override
    TestTrack.enabled_override = true
    yield
  ensure
    TestTrack.enabled_override = previous_value
  end
end
