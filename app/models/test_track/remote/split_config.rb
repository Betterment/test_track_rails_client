class TestTrack::Remote::SplitConfig
  include TestTrack::Resource

  attribute :name
  attribute :weighting_registry

  validates :name, :weighting_registry, presence: true

  def self.destroy_existing(id)
    connection.delete("api/v1/split_configs/#{id}") unless faked?
    nil
  end

  def save
    return false unless valid?

    body = { name:, weighting_registry: }
    connection.post("api/v1/split_configs", body) unless faked?
    true
  end
end
