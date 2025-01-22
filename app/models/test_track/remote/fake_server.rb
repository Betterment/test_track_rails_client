class TestTrack::Remote::FakeServer
  def self.reset!(seed)
    raise('Cannot reset FakeServer if TestTrack is enabled.') if TestTrack.enabled?

    TestTrack::Resource.connection.put('api/v1/reset', seed:)
  end
end
