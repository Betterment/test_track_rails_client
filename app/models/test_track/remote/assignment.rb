class TestTrack::Remote::Assignment
  include TestTrack::RemoteModel

  collection_path '/api/v1/assignment'

  attributes :visitor_id, :split_name, :variant, :unsynced

  validates :visitor_id, :split_name, :variant, :mixpanel_result, presence: true

  def fake_save_response_attributes
    nil # :no_content is the expected response type
  end
end
