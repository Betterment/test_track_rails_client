class TestTrack::Remote::Visitor
  include TestTrack::TestTrackModel

  def self.fake_instance_attributes(_)
    {
      id: "fake_visitor_id",
      assignment_registry: {
        time: 'hammertime'
      }
    }
  end

  def self.from_identifier(identifier_type_name, identifier_value)
    raise "must provide an identifier_type_name" unless identifier_type_name.present?
    raise "must provide an identifier_value" unless identifier_value.present?

    # TODO: FakeableHer needs to make this faking a feature of `get`
    if ENV['TEST_TRACK_ENABLED']
      get("/api/identifier_types/#{identifier_type_name}/identifiers/#{identifier_value}/visitor")
    else
      new(fake_instance_attributes(nil))
    end
  end
end
