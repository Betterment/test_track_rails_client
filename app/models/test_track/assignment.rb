class TestTrack::Assignment
  attr_reader :visitor, :split_name
  attr_writer :variant

  def initialize(visitor, split_name)
    @visitor = visitor
    @split_name = split_name
  end

  def variant
    @variant ||= (TestTrack::VariantCalculator.new(visitor: visitor, split_name: split_name).variant if visitor.known_visitor?)
  end

  def unsynced?
    true
  end
end
