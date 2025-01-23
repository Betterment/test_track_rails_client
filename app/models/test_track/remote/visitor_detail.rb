class TestTrack::Remote::VisitorDetail
  include TestTrack::Resource

  attr_reader :assignment_details

  def self.from_identifier(identifier_type, identifier_value)
    result = request(
      method: :get,
      path: "api/v1/identifier_types/#{identifier_type}/identifiers/#{identifier_value}/visitor_detail",
      fake: fake_instance_attributes(nil)
    )

    new(result)
  end

  def self.fake_instance_attributes(_)
    {
      assignment_details: [
        TestTrack::Remote::AssignmentDetail.fake_instance_attributes(nil),
        TestTrack::Remote::AssignmentDetail.fake_instance_attributes(nil)
      ]
    }
  end

  def assignment_details=(values)
    @assignment_details = values.map do |value|
      TestTrack::Remote::AssignmentDetail.new(value)
    end
  end
end
