class TestTrack::Fake::SplitDetail
  include Singleton

  def details
    @details ||= _details
  end

  private

  def _details
    {
      name: "banner_color",
      hypothesis: "user will interact more with blue banner",
      location: "home screen",
      platform: "mobile",
      owner: "mobile team",
      assignment_criteria: "user has mobile app",
      description: "banner test to see if users will interact more"
    }
  end
end
