class TestTrack::Fake::Split
  def self.instance
    @instance ||= new
  end

  def split_details
    @split_details ||= _split_details
  end

  private

  def _split_details
    split_hash = TestTrack::Fake::Schema.split_hash
    split_hash.each_with_object({}) do |(split_name, details), split_details|
      details_without_weight = details.except!("weights")
      split_details["name"] = split_name
      split_details.merge!(details_without_weight)
    end
  end
end
