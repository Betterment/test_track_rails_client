module TestTrackRails
  class SplitRegistry
    include TestTrackModel

    collection_path '/api/split_registry'

    def self.fake_instance_attributes(_)
      { hammertime: 100 }
    end

    def self.instance
      # TODO: FakeableHer needs to make this faking a feature of `get`
      if ENV['TEST_TRACK_ENABLED']
        get('/api/split_registry')
      else
        new(fake_instance_attributes(nil))
      end
    end
  end
end
