class TestTrack::Remote::SplitConfig
  include TestTrack::Resource
  include TestTrack::Persistence

  attribute :name
  attribute :weighting_registry

  validates :name, :weighting_registry, presence: true

  def self.destroy_existing(id)
    TestTrack::Client.request(
      method: :delete,
      path: "api/v1/split_configs/#{id}",
      fake: nil
    )

    nil
  end

  private

  def persist!
    TestTrack::Client.request(
      method: :post,
      path: 'api/v1/split_configs',
      body: { name: name, weighting_registry: weighting_registry },
      fake: nil
    )
  end
end
