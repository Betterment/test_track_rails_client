class TestTrack::Remote::Identifier
  include TestTrack::RemoteModel

  collection_path '/api/v1/identifier'

  has_one :remote_visitor, data_key: :visitor, class_name: "TestTrack::Remote::Visitor"

  attributes :identifier_type, :visitor_id, :value

  validates :identifier_type, :visitor_id, :value, presence: true

  def fake_save_response_attributes
    { visitor: { id: visitor_id, assignments: [] } }
  end

  def visitor
    @visitor ||= TestTrack::Visitor.new(visitor_opts!)
  end

  private

  def visitor_opts!
    raise("Visitor data unavailable until you save this identifier.") unless attributes[:remote_visitor]
    { id: remote_visitor.id, assignments: remote_visitor.assignments }
  end
end
