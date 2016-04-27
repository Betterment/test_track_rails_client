class TestTrack::VisitorDSL
  def initialize(visitor)
    @visitor = visitor
  end

  delegate :vary, :ab, :id, to: :visitor

  private

  attr_reader :visitor
end
