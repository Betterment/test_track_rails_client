class TestTrack::SplitRegistry
  def self.from_remote
    new(TestTrack::Remote::SplitRegistry.to_hash)
  end

  def initialize(registry_hash)
    @registry_hash = registry_hash
  end

  def include?(split_name)
    registry_hash['splits'].key?(split_name)
  end

  def loaded?
    registry_hash.present?
  end

  def split_names
    registry_hash['splits'].keys
  end

  def experience_sampling_weight
    registry_hash.fetch('experience_sampling_weight')
  end

  def weights_for(split_name)
    registry_hash && registry_hash['splits'][split_name] && registry_hash['splits'][split_name]['weights'].freeze
  end

  def to_v1_hash
    registry_hash && registry_hash['splits'].each_with_object({}) do |(k, v), result|
      result[k] = v['weights']
    end
  end

  private

  attr_reader :registry_hash
end
