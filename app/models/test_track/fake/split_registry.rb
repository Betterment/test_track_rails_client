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

  def split_hash
    if test_track_schema_yml.present?
      test_track_schema_yml[:splits]
    else
      {}
    end
  end

  def test_track_schema_yml
    unless instance_variable_defined?(:@test_track_schema_yml)
      @test_track_schema_yml = _test_track_schema_yml
    end
    @test_track_schema_yml
  end

  def _test_track_schema_yml
    YAML.load_file(test_track_schema_yml_path).with_indifferent_access
  rescue
    nil
  end

  def test_track_schema_yml_path
    ENV["TEST_TRACK_SCHEMA_FILE_PATH"] || "#{Rails.root}/db/test_track_schema.yml"
  end

  def splits_with_deterministic_weights
    split_hash.each_with_object({}) do |(split_name, weighting_registry), split_registry|
      default_variant = weighting_registry.keys.sort.first

      adjusted_weights = { default_variant => 100 }
      weighting_registry.except(default_variant).keys.each do |variant|
        adjusted_weights[variant] = 0
      end

      split_registry[split_name] = adjusted_weights
    end
  end
end
