class TestTrack::Fake::Split
  include Singleton

  def split_details
    @split_details ||= _split_details
  end

  private

  def _split_details
    split_hash = TestTrack::Fake::Schema.instance.split_hash
    { "name" => "banner_color" }.merge(split_hash["banner_color"].except("weights"))
  end
end
