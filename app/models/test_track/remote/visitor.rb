class TestTrack::Remote::Visitor
  include TestTrack::RemoteModel

  collection_path '/api/visitors'

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
