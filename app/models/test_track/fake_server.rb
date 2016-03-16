class TestTrack::FakeServer
  class << self
    def split_registry
      TestTrack::Fake::SplitRegistry.instance.as_splits
    end

    def visitor
      TestTrack::Fake::Visitor.instance
    end

    def assignments
      TestTrack::Fake::Visitor.instance.assignments
    end
  end
end
