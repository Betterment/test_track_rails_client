module TestTrackRails
  class SplitRegistry
    include TestTrackModel

    collection_path '/api/split_registry'

    def self.fake_instance_attributes(_)
      {
        time: { hammertime: 100, clobberin_time: 0 },
        blue_button: { true: 50, false: 50 }
      }
    end

    def self.instance
      # TODO: FakeableHer needs to make this faking a feature of `get`
      if ENV['TEST_TRACK_ENABLED']
        get('/api/split_registry')
      else
        new(fake_instance_attributes(nil))
      end
    end

    def self.to_hash
      Rails.cache.fetch('test_track_split_registry', expires_in: 5.seconds) do
        instance.attributes
      end.freeze
    rescue Faraday::TimeoutError
      nil # if we can't get a split registry
    end
  end
end
