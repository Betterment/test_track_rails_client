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
    raise "Invalid visitor: #{value.inspect}" unless value.is_a?(Hash)

    @visitor = TestTrack::Remote::Visitor.new(value).to_visitor
  end

  def save
    return false unless valid?

    body = {
      identifier_type:,
      visitor_id:,
      value:,
    }

    self.visitor = if faked?
      { 'id' => visitor_id, 'assignments' => [] }
    else
      response = connection.post('api/v1/identifier', body)
      response.body.fetch('visitor')
    end

    true
  end
end
