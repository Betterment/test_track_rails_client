class TestTrack::Remote::AssignmentDetail
  include TestTrack::Resource

  attribute :split_location
  attribute :split_name
  attribute :variant_name
  attribute :variant_description
  attribute :assigned_at, :datetime

  def self.fake_instance_attributes(_)
    {
      split_name: 'excellent_feature',
      split_location: 'Sign up',
      variant_name: 'Excellent feature enabled',
      variant_description: 'This feature is on which means something will be different.',
      assigned_at: '2017-04-10T05:00:00Z'
    }
  end
end
