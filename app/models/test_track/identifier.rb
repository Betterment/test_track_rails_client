class TestTrack::Identifier
  include TestTrack::TestTrackModel

  collection_path '/api/identifier'

  attributes :identifier_type, :visitor_id, :value

  validates :identifier_type, :visitor_id, :value, presence: true

  def fake_save_response_attributes
    { visitor: { id: visitor_id, assignment_registry: {} } }
  end

  def visitor
    @visitor ||= TestTrack::Visitor.new(visitor_opts!)
  end

  private

  def visitor_opts!
    attributes[:visitor] || raise("Visitor data unavailable until you save this identifier.")
  end
end
