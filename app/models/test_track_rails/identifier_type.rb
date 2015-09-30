module TestTrackRails
  class IdentifierType
    include TestTrackModel

    collection_path '/identifier_type'

    attributes :name

    validates :name, presence: true

    def fake_save_response_attributes
      nil # :no_content is the expected response type
    end
  end
end
