class TestTrack::Remote::SplitDetail
  include TestTrack::RemoteModel

  collection_path '/api/v1/split_details'

  attributes :name, :hypothesis, :assignment_criteria, :description, :owner, :location, :platform

  def self.from_name(name)
    # TODO: FakeableHer needs to make this faking a feature of `get`
    if faked?
      new(fake_instance_attributes(name))
    else
      get("/api/v1/split_details/#{name}")
    end
  end

  def self.fake_instance_attributes(name)
    {
      name: name,
      hypothesis: "fake hypothesis",
      assignment_criteria: "fake criteria for everyone",
      description: "fake but still good description",
      owner: "fake owner",
      location: "fake activity",
      platform: "mobile"
    }
  end
end
