class TestTrack::Assignment
  attr_reader :visitor, :split_name
  attr_writer :variant

  def initialize(visitor, split_name)
    @visitor = visitor
    @split_name = split_name.to_s
  end

  def variant
    @variant ||= (TestTrack::VariantCalculator.new(visitor: visitor, split_name: split_name).variant.to_s unless visitor.offline?)
  end

  def unsynced?
    true
  end
end
