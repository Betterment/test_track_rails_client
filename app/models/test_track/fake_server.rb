class TestTrack::FakeServer
  class << self
    def split_registry
      TestTrack::Fake::SplitRegistry.instance.splits
    end

    def visitor
      TestTrack::Fake::Visitor.instance
    end

    def assignments
      TestTrack::Fake::Visitor.instance.assignments
    end

    def reset!(seed = rand(1000))
      @seed = seed.to_i
    end

    def seed
      @seed || reset!
    end
  end
end
