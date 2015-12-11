class TestTrack::VisitorDSL
  def initialize(visitor)
    @visitor = visitor
  end

  delegate :vary, :ab, to: :visitor

  private

  attr_reader :visitor
end
