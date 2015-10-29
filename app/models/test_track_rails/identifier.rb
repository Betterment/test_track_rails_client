module TestTrackRails
  class Identifier
    include TestTrackModel

    collection_path '/api/identifier'

    attributes :identifier_type, :visitor_id, :value

    validates :identifier_type, :visitor_id, :value, presence: true

    def fake_save_response_attributes
      { visitor: { id: visitor_id, assignment_registry: {} } }
    end

    def visitor
      @visitor ||= Visitor.new(visitor_hash!)
    end

    private

    def visitor_hash!
      attributes[:visitor] || raise("Visitor data unavailable until you save this identifier.")
    end
  end
end
