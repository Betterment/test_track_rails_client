class TestTrack::Remote::AssignmentDetail
  include TestTrack::RemoteModel

  collection_path '/api/v1/visitors/:visitor_id/assignment_details'

  attributes :split_location, :split_name, :variant_name, :variant_description, :assigned_at

  def self.fake_collection_attributes(_)
    [
      {
        split_name: 'excellent_feature',
        split_location: 'Sign up',
        display_name: 'Excellent feature enabled',
        description: 'This feature is on which means something will be different.',
        assigned_at: '2017-04-10T05:00:00Z'
      },
      {
        split_name: 'other_feature',
        split_location: 'Home page',
        display_name: 'Other feature disabled',
        description: 'Another feature is off, so nothing will be different',
        assigned_at: '2017-04-10T05:00:00Z'
      }
    ]
  end
end
