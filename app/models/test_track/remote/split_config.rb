class TestTrack::Remote::SplitConfig
  include TestTrack::RemoteModel

  collection_path 'api/v1/split_configs'

  attributes :name, :weighting_registry

  validates :name, :weighting_registry, presence: true

  def fake_save_response_attributes
    nil # :no_content is the expected response type
  end
end
