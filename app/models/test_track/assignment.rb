class TestTrack::Assignment
  attr_reader :visitor, :split_name
  attr_writer :variant

  def initialize(visitor, split_name)
    @visitor = visitor
    @split_name = split_name.to_s
  end

  def variant
    @variant ||= _variant
  end

  def unsynced?
    true
  end

  private

  def _variant
    return if visitor.offline?
    variant = TestTrack::VariantCalculator.new(visitor: visitor, split_name: split_name).variant
    variant && variant.to_s
  end
end
