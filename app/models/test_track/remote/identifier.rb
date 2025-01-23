class TestTrack::Remote::Identifier
  include TestTrack::Resource

  attribute :identifier_type
  attribute :visitor_id
  attribute :value

  validates :identifier_type, :visitor_id, :value, presence: true

  def self.create!(attributes)
    identifier = new(attributes)
    identifier.validate!
    identifier.save
    identifier
  end

  def visitor
    @visitor or raise('Visitor data unavailable until you save this identifier.')
  end

  def visitor=(value)
    @visitor = TestTrack::Remote::Visitor.new(value).to_visitor
  end

  def save
    return false unless valid?

    result = request(
      method: :post,
      path: 'api/v1/identifier',
      body: { identifier_type: identifier_type, visitor_id: visitor_id, value: value },
      fake: { visitor: { id: visitor_id, assignments: [] } }
    )

    self.visitor = result.fetch('visitor')

    true
  end
end
