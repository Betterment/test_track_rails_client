class TestTrack::Remote::SplitRegistry
  include TestTrack::RemoteModel

  CACHE_KEY = 'test_track_split_registry'.freeze

  collection_path '/api/v2/split_registry'

  class << self
    def fake_instance_attributes(_)
      ::TestTrack::Fake::SplitRegistry.instance.to_h
    end

    def instance
      # TODO: FakeableHer needs to make this faking a feature of `get`
      if faked?
        new(fake_instance_attributes(nil))
      else
        get('/api/v2/split_registry')
      end
    end

    def reset
      Rails.cache.delete(CACHE_KEY)
    end

    def to_hash
      if faked?
        instance.attributes.freeze
      else
        fetch_cache { instance.attributes }.freeze
      end
    rescue *TestTrack::SERVER_ERRORS => e
      Rails.logger.error "TestTrack failed to load split registry. #{e}"
      fetch_cache { nil } # cache the missing registry for 5 seconds if we can't get one
    end

    private

    def fetch_cache(&block)
      Rails.cache.fetch(CACHE_KEY, expires_in: 5.seconds, &block)
    end
  end
end
