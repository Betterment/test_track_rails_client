class TestTrack::VisitorDSL
  def initialize(visitor)
    @visitor = visitor
  end

  delegate :vary, :ab, :log_in!, :sign_up!, to: :visitor

  private

  attr_reader :visitor
end
