class TestTrack::Remote::FakeServer
  include TestTrack::RemoteModel

  def self.reset!(seed)
    TestTrack.enabled? ? raise('Cannot reset FakeServer if TestTrack is enabled.') : put('api/reset', seed: seed)
  end
end
