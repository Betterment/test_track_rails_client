class TestTrack::Fake::Visitor
  attr_reader :id

  Assignment = Struct.new(:split_name, :variant)

  def self.instance
    @instance ||= new(TestTrack::FakeServer.seed)
  end

  def self.reset!
    @instance = nil
  end

  def initialize(id)
    @id = id
  end

  def assignments
    @assignments ||= _assignments
  end

  def unsynced_splits
    []
  end

  def assignment_registry
    Hash[assignments.map { |assignment| [assignment.split_name.to_sym, assignment.variant.to_sym] }]
  end

  private

  def _assignments
    TestTrack::Fake::SplitRegistry.instance.splits.map do |split|
      index = TestTrack::FakeServer.seed % split.registry.keys.size
      variant = split.registry.keys[index]
      Assignment.new(split.name, variant)
    end
  end
end
