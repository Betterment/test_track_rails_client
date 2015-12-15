class TestTrack::Remote::SplitConfig
  include TestTrack::TestTrackModel

  collection_path '/api/split_config'

  attributes :name, :weighting_registry

  validates :name, :weighting_registry, presence: true

  def fake_save_response_attributes
    nil # :no_content is the expected response type
  end
end
