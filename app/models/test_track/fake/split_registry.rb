class TestTrack::Fake::SplitRegistry
  Split = Struct.new(:name, :registry) do
    def sample_variant
      index = Rails.env.test? ? RSpec.configuration.seed % registry.keys.size : 0
      registry.keys[index]
    end
  end

  def self.instance
    @instance ||= new
  end

  def to_h
    if test_track_schema_yml.present?
      test_track_schema_yml[:splits]
    else
      {}
    end
  end

  def splits
    to_h.map do |split, registry|
      Split.new(split, registry)
    end
  end

  private

  def test_track_schema_yml
    unless instance_variable_defined?(:@test_track_schema_yml)
      @test_track_schema_yml = _test_track_schema_yml
    end
    @test_track_schema_yml
  end

  def _test_track_schema_yml
    YAML.load_file("#{Rails.root}/db/test_track_schema.yml").with_indifferent_access
  rescue
    nil
  end
end
