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

    def reset!(seed)
      TestTrack::Fake::Visitor.reset!
      @seed = seed.to_i
    end

    def seed
      @seed || raise('TestTrack::FakeServer seed not set. Call TestTrack::FakeServer.reset!(seed) to set seed.')
    end
  end
end
