class TestTrack::Fake::Visitor
  attr_reader :id

  Assignment = Struct.new(:split_name, :variant, :unsynced, :context)

  def self.instance
    @instance ||= new(TestTrack::FakeServer.seed)
  end

  def self.reset!
    @instance = nil
    TestTrack::Fake::SplitRegistry.reset!
  end

  def initialize(id)
    @id = id
  end

  def assignments
    @assignments ||= _assignments
  end

  def split_registry
    TestTrack::SplitRegistry.new(TestTrack::Fake::SplitRegistry.instance.to_h)
  end

  private

  def _assignments
    split_registry.split_names.map do |split_name|
      variant = TestTrack::VariantCalculator.new(visitor: self, split_name: split_name).variant
      Assignment.new(split_name, variant, false, "the_context")
    end
  end
end
