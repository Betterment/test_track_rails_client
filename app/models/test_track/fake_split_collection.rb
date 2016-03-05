class TestTrack::FakeSplitCollection
  class << self
    def to_h
      if test_track_schema_yml.present?
        splits
      else
        {}
      end
    end

    private

    def splits
      @splits ||= test_track_schema_yml[:splits]
    end

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
end
