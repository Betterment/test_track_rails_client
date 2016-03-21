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
      @seed = seed
    end

    def seed
      (@seed || reset!).to_i
    end
  end
end
