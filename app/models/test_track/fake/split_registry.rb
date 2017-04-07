class TestTrack::Fake::SplitRegistry
  Split = Struct.new(:name, :registry)

  def self.instance
    @instance ||= new
  end

  def to_h
    @to_h ||= splits_with_deterministic_weights
  end

  def splits
    to_h.map do |split, registry|
      Split.new(split, registry)
    end
  end

  private

  def splits_with_deterministic_weights
    split_hash = TestTrack::Fake::Schema.split_hash
    split_hash.each_with_object({}) do |(split_name, weighting_registry), split_registry|
      default_variant = weighting_registry["weights"].keys.sort.first

      adjusted_weights = { default_variant => 100 }
      weighting_registry["weights"].except(default_variant).keys.each do |variant|
        adjusted_weights[variant] = 0
      end

      split_registry[split_name] = adjusted_weights
    end
  end
end
