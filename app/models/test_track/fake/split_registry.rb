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
    file = YAML.load_file(schema_yml_path)
    file && file['splits'].each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |split, h|
      h[split['name']] = split['weights']
    end
  end

  def schema_yml_path
    base = ENV['TEST_TRACK_SCHEMA_ROOT'] || Rails.root
    File.join(base, 'testtrack', 'schema.yml')
  end

  def legacy_test_track_schema_yml
    unless instance_variable_defined?(:@legacy_test_track_schema_yml)
      @legacy_test_track_schema_yml = _legacy_test_track_schema_yml
    end
    @legacy_test_track_schema_yml
  end

  def _legacy_test_track_schema_yml
    YAML.load_file(legacy_test_track_schema_yml_path).with_indifferent_access
  rescue
    nil
  end

  def legacy_test_track_schema_yml_path
    ENV["TEST_TRACK_SCHEMA_FILE_PATH"] || Rails.root.join('db', 'test_track_schema.yml')
  end

  def splits_with_deterministic_weights
    split_hash.each_with_object({}) do |(split_name, weighting_registry), split_registry|
      default_variant = weighting_registry.keys.sort.first

      adjusted_weights = { default_variant => 100 }
      weighting_registry.except(default_variant).each_key do |variant|
        adjusted_weights[variant] = 0
      end

      split_registry[split_name] = adjusted_weights
    end
  end
end
