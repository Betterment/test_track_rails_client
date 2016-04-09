class TestTrack::Assignment
  attr_reader :visitor, :split_name
  attr_writer :variant

  def initialize(visitor, split_name)
    @visitor = visitor
    @split_name = split_name
  end

  def variant
    @variant ||= TestTrack::VariantCalculator.new(visitor: visitor, split_name: split_name).variant unless visitor.send :tt_offline?
  end

  def unsynced?
    true
  end
end
