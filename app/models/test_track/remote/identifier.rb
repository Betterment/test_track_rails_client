class TestTrack::Remote::Identifier
  include TestTrack::RemoteModel

  collection_path '/api/identifier'

  attributes :identifier_type, :visitor_id, :value

  validates :identifier_type, :visitor_id, :value, presence: true

  def fake_save_response_attributes
    { visitor: { id: visitor_id, assignment_registry: {}, unsynced_splits: [] } }
  end

  def visitor
    @visitor ||= TestTrack::Visitor.new(visitor_opts!)
  end

  private

  def visitor_opts!
    raise("Visitor data unavailable until you save this identifier.") unless attributes[:visitor]
    attributes[:visitor].slice(:id, :assignment_registry)
  end
end
