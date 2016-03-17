class TestTrack::Fake::Visitor
  attr_reader :id

  def self.instance
    @instance ||= new('39b30d44-fb0c-459c-bab1-352fa385a448')
  end

  def initialize(id)
    @id = id
  end

  def assignments
    TestTrack::Fake::SplitRegistry.instance.splits
  end

  def unsynced_splits
    []
  end

  def assignment_registry
    Hash[assignments.map { |a| [a.name.to_sym, a.sample_variant.to_sym] }]
  end
end
