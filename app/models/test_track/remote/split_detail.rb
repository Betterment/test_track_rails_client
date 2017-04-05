class TestTrack::Remote::SplitDetail
  include TestTrack::RemoteModel

  collection_path '/api/v1/split_details'

  attributes :name

  def self.from_name(name)
    raise "must provide a name" unless name.present?

    # TODO: FakeableHer needs to make this faking a feature of `get`
    if faked?
      new(fake_instance_attributes(nil))
    else
      get("/api/v1/split_details/#{name}")
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
