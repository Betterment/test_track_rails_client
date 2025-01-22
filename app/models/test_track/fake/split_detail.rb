class TestTrack::Fake::SplitDetail
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def details
    @details ||= _details
  end

  private

  def _details
    {
      name:,
      hypothesis: "user will interact more with blue banner",
      location: "home screen",
      platform: "mobile",
      owner: "mobile team",
      assignment_criteria: "user has mobile app",
      description: "banner test to see if users will interact more",
      variant_details:
    }
  end

  def variant_details
    [
      {
        name: "first variant detail",
        description: "red banner on homepage"
      },
      {
        name: "second variant detail",
        description: "yellow banner on homepage"
      }
    ]
  end
end
