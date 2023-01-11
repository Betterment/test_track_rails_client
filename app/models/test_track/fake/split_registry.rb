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
    if schema_registry.present?
      schema_registry
    elsif legacy_test_track_schema_yml.present?
      legacy_test_track_schema_yml[:splits]
    else
      {}
    end
  end

  def schema_registry
    @schema_registry = _schema_registry unless instance_variable_defined?(:@schema_registry)
    @schema_registry
  end

  def _schema_registry
    file = File.exist?(schema_yml_path) &&
      YAML.load_file(schema_yml_path)
    file && file['splits'].each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |split, h|
      h[split['name']] = split['weights']
    end
  end

  def schema_yml_path
    base = ENV['TEST_TRACK_SCHEMA_ROOT'] || Rails.root
    File.join(base, 'testtrack', 'schema.yml')
  end

  def legacy_test_track_schema_yml
    @legacy_test_track_schema_yml = _legacy_test_track_schema_yml unless instance_variable_defined?(:@legacy_test_track_schema_yml)
    @legacy_test_track_schema_yml
  end

  def _legacy_test_track_schema_yml
    File.exist?(legacy_test_track_schema_yml_path) &&
      YAML.load_file(legacy_test_track_schema_yml_path).with_indifferent_access
  rescue StandardError
    nil
  end

  def legacy_test_track_schema_yml_path
    ENV["TEST_TRACK_SCHEMA_FILE_PATH"] || Rails.root.join('db/test_track_schema.yml').to_s
  end

  def split_registry_with_deterministic_weights
    splits = split_hash.each_with_object({}) do |(split_name, weighting_registry), result|
      default_variant = weighting_registry.invert[100] || weighting_registry.keys.min

      adjusted_weights = { default_variant => 100 }
      weighting_registry.except(default_variant).each_key do |variant|
        adjusted_weights[variant] = 0
      end

      result[split_name] = { 'weights' => adjusted_weights, 'feature_gate' => split_name.end_with?('_enabled') }
    end
    { 'splits' => splits, 'experience_sampling_weight' => 1 }
  end
end
