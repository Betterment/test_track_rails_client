class TestTrack::Remote::IdentifierType
  include TestTrack::RemoteModel

  collection_path '/api/v1/identifier_type'

  attributes :name

  validates :name, presence: true

  def fake_save_response_attributes
    nil # :no_content is the expected response type
  end
end
