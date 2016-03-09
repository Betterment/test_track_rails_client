class TestTrack::FakeTestTrack
  class << self
    def split_registry
      TestTrack::Fake::SplitRegistry.as_splits
    end

    def visitor
      TestTrack::Fake::Visitor.instance
    end

    def assignments
      TestTrack::Fake::Visitor.instance.assignments
    end

    def state_hash
      {
        url: "#{ENV['RETAIL_API_URL']}/tt",
        cookieDomain: '.betterment.qa',
        registry: TestTrack::FakeTestTrack.split_registry,
        assignments: TestTrack::FakeTestTrack.visitor.assignment_registry
      }
    end
  end
end
