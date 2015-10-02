module TestTrackRails
  class AssignmentRegistry
    include TestTrackModel

    def self.fake_instance_attributes(_)
      { time: 'hammertime' }
    end

    def self.for_visitor(visitor_id)
      raise "must provide a visitor_id" unless visitor_id
      # TODO: FakeableHer needs to make this faking a feature of `get`
      if ENV['TEST_TRACK_ENABLED']
        get("/api/visitors/#{URI.escape(visitor_id)}/assignment_registry")
      else
        new(fake_instance_attributes(nil))
      end
    end
  end
end
