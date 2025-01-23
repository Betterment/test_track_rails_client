class TestTrack::Remote::Identifier
  include TestTrack::Resource
  include TestTrack::Persistence

  attribute :identifier_type
  attribute :visitor_id
  attribute :value

  validates :identifier_type, :visitor_id, :value, presence: true

  def visitor
    @visitor or raise('Visitor data unavailable until you save this identifier.')
  end

  def visitor=(value)
    @visitor = TestTrack::Remote::Visitor.new(value).to_visitor
  end

  private

  def persist!
    result = TestTrack::Client.request(
      method: :post,
      path: 'api/v1/identifier',
      body: { identifier_type: identifier_type, visitor_id: visitor_id, value: value },
      fake: { visitor: { id: visitor_id, assignments: [] } }
    )

    assign_attributes(result)
  end
end
