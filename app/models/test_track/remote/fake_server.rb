class TestTrack::Remote::FakeServer
  include TestTrack::RemoteModel

  def self.reset!(seed)
    raise('Cannot reset FakeServer if TestTrack is enabled.') if TestTrack.enabled?
    put('api/reset', seed: seed)
  end
end
