class TestTrack::Remote::Assignment
  include TestTrack::RemoteModel

  collection_path '/api/v1/assignment'

  attributes :visitor_id, :split_name, :variant, :unsynced

  validates :visitor_id, :split_name, :variant, :mixpanel_result, presence: true

  def unsynced?
    unsynced || variant_changed?
  end

  def fake_save_response_attributes
    nil # :no_content is the expected response type
  end

  def self.fake_instance_attributes(id)
    {
      split_name: "split_#{id}",
      variant: "true",
      unsynced: false
    }
  end
end
