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
      name: name,
      hypothesis: "user will interact more with blue banner",
      location: "home screen",
      platform: "mobile",
      owner: "mobile team",
      assignment_criteria: "user has mobile app",
      description: "banner test to see if users will interact more"
    }
  end
end
