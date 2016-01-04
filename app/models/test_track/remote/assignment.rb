class TestTrack::Remote::Assignment
  include TestTrack::RemoteModel

  collection_path '/api/assignment'

  attributes :visitor_id, :split, :variant

  validates :visitor_id, :split, :variant, :mixpanel_result, presence: true

  def fake_save_response_attributes
    nil # :no_content is the expected response type
  end
end
