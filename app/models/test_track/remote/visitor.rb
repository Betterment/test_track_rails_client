class TestTrack::Remote::Visitor
  include TestTrack::RemoteModel

  collection_path '/api/v1/visitors'

  def self.fake_instance_attributes(_)
    {
      id: "fake_visitor_id",
      assignment_registry: {
        time: 'hammertime'
      },
      unsynced_splits: []
    }
  end
end
