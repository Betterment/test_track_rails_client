class TestTrack::Fake::Visitor
  attr_reader :id

  Assignment = Struct.new(:split_name, :variant)

  def self.instance
    @instance ||= new('39b30d44-fb0c-459c-bab1-352fa385a448')
  end

  def initialize(id)
    @id = id
  end

  def assignments
    TestTrack::Fake::SplitRegistry.instance.splits.map do |split|
      index = TestTrack::FakeServer.seed % split.registry.keys.size
      variant = split.registry.keys[index]
      Assignment.new(split.name, variant)
    end
  end

  def unsynced_splits
    []
  end

  def assignment_registry
    Hash[assignments.map { |assignment| [assignment.split_name.to_sym, assignment.variant.to_sym] }]
  end
end
