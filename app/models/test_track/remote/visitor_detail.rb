class TestTrack::Remote::VisitorDetail
  include TestTrack::RemoteModel

  has_many :assignment_details

  def self.from_identifier(identifier_type, identifier_value)
    # TODO: FakeableHer needs to make this faking a feature of `get`
    if faked?
      new(fake_instance_attributes(nil))
    else
      get("api/v1/identifier_types/#{identifier_type}/identifiers/#{identifier_value}/visitor_detail")
    end
  end

  def self.fake_instance_attributes(_)
    {
      assignment_details: [
        TestTrack::Remote::AssignmentDetail.fake_instance_attributes(nil),
        TestTrack::Remote::AssignmentDetail.fake_instance_attributes(nil)
      ]
    }
  end
end
