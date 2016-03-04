class FakeSplitCollection
  class << self
    def to_h
      if test_track_schema_yml
        splits
      else
        default_splits
      end
    end

    private

    def default_splits
      {
        time: { hammertime: 100, clobberin_time: 0 },
        blue_button: { true: 50, false: 50 }
      }
    end

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
