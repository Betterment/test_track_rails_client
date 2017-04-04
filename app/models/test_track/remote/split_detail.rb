class TestTrack::Remote::SplitDetail
  include TestTrack::RemoteModel

  collection_path '/api/v1/split_details'

  attributes :name

  def self.from_identifier(identifier_value)
    raise "must provide an identifier_value" unless identifier_value.present?

    # TODO: FakeableHer needs to make this faking a feature of `get`
    if faked?
      new(fake_instance_attributes(nil))
    else
      get("/api/v1/split_details/#{identifier_value}")
    end
  end

  def self.fake_instance_attributes(_)
    {
      split_name: "fake_visitor_id",
      hypothesis: "fake_hypothesis",
      assignment_criteria: "fake_criteria",
      description: "fake_description",
      owner: "fake_retail",
      location: "fake_activity",
      platform: "fake_mobile"
    }
  end
end
