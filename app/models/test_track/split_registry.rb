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

  def to_hash
    registry_hash && registry_hash['splits'].transform_values do |v|
      { weights: v['weights'], feature_gate: v['feature_gate'] }
    end
  end

  private

  attr_reader :registry_hash
end
