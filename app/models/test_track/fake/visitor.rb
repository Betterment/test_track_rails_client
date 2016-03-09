class TestTrack::Fake::Visitor
  Visitor = Struct.new(:id) do
    def assignments
      TestTrack::Fake::SplitRegistry.as_splits
    end

    def unsynced_splits
      []
    end

    def assignment_registry
      Hash[assignments.map { |a| [a.name.to_sym, a.sample_variant.to_sym] }]
    end
  end

  def self.instance
    Visitor.new('39b30d44-fb0c-459c-bab1-352fa385a448')
  end
end
