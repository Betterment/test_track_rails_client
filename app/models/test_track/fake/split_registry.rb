class TestTrack::Fake::SplitRegistry
  Split = Struct.new(:name, :registry)

  def self.instance
    @instance ||= new
  end

  def self.reset!
    @instance = nil
  end

  def to_h
    @to_h ||= split_registry_with_deterministic_weights
  end

  def splits
    to_h['splits'].map do |split_name, registry|
      Split.new(split_name, registry['weights'])
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
    ENV["TEST_TRACK_SCHEMA_FILE_PATH"] || Rails.root.join('db', 'test_track_schema.yml')
  end

  def split_registry_with_deterministic_weights
    splits = split_hash.each_with_object({}) do |(split_name, weighting_registry), result|
      default_variant = weighting_registry.keys.sort.first

      adjusted_weights = { default_variant => 100 }
      weighting_registry.except(default_variant).each_key do |variant|
        adjusted_weights[variant] = 0
      end

      result[split_name] = { 'weights' => adjusted_weights, 'feature_gate' => split_name.end_with?('_enabled') }
    end
    { 'splits' => splits, 'experience_sampling_weight' => 1 }
  end
end
