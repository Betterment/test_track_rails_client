class TestTrack::Remote::SplitConfig
  include TestTrack::Resource

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

  def save
    return false unless valid?

    TestTrack::Client.request(
      method: :post,
      path: 'api/v1/split_configs',
      body: { name: name, weighting_registry: weighting_registry },
      fake: nil
    )

    true
  end
end
