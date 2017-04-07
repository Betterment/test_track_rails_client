class TestTrack::Fake::Schema
  include Singleton

  def split_hash
    @split_hash ||= _split_hash
  end

  private

  def _split_hash
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
end
