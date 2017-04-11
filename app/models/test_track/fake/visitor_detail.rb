class TestTrack::Fake::VisitorDetail
  # rubocop:disable Metrics/MethodLength
  def self.instance
    {
      assignment_details: [
        {
          split_name: 'really_cool_feature',
          split_location: 'Home page',
          variant_name: 'Enabled',
          variant_description: 'The feature is enabled',
          assigned_at: '2017-04-11T00:00:00Z'
        }
      ]
    }
  end
  # rubocop:enable Metrics/MethodLength
end
