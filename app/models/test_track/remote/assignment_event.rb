class TestTrack::Remote::AssignmentEvent
  include TestTrack::RemoteModel

  collection_path '/api/v1/assignment_event'

  attributes :visitor_id, :split_name, :mixpanel_result, :context

  validates :visitor_id, :split_name, :mixpanel_result, presence: true

  def fake_save_response_attributes
    nil # :no_content is the expected response type
  end
end
