class TestTrack::Remote::Visitor
  include TestTrack::RemoteModel

  collection_path '/api/v1/visitors'

  def self.from_identifier(identifier_type, identifier_value)
    raise "must provide an identifier_type" unless identifier_type.present?
    raise "must provide an identifier_value" unless identifier_value.present?

    # TODO: FakeableHer needs to make this faking a feature of `get`
    if faked?
      new(fake_instance_attributes(nil))
    else
      get("/api/v1/identifier_types/#{identifier_type}/identifiers/#{identifier_value}/visitor")
    end
  end

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
