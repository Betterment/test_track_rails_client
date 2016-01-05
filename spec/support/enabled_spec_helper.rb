module EnabledSpecHelper
  def with_test_track_enabled
    allow(TestTrack).to receive(:enabled?).and_return(true)
    yield
  ensure
    allow(TestTrack).to receive(:enabled?).and_call_original
  end
end
