class TestTrack::Remote::Visitor
  include TestTrack::RemoteModel

  collection_path 'api/v1/visitors'

  has_many :assignments

  def self.from_identifier(identifier_type, identifier_value)
    raise "must provide an identifier_type" if identifier_type.blank?
    raise "must provide an identifier_value" if identifier_value.blank?

    # TODO: FakeableHer needs to make this faking a feature of `get`
    if faked?
      new(fake_instance_attributes(nil))
    else
      get("api/v1/identifier_types/#{identifier_type}/identifiers/#{identifier_value}/visitor")
    end
  end

  def self.fake_instance_attributes(_)
    {
      id: "fake_visitor_id",
      assignments: [
        TestTrack::Remote::Assignment.fake_instance_attributes(1),
        TestTrack::Remote::Assignment.fake_instance_attributes(2)
      ]
    }
  end
end
