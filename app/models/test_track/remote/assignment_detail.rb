class TestTrack::Remote::AssignmentDetail
  include TestTrack::RemoteModel

  attributes :split_location, :split_name, :variant_name, :variant_description, :assigned_at

  def assigned_at
    original = super
    if original.blank? || !original.respond_to?(:in_time_zone)
      nil
    else
      original.in_time_zone rescue nil # rubocop:disable Style/RescueModifier
    end
  end

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
