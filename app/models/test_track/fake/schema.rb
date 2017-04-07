class TestTrack::Fake::Schema
  include Singleton

  def self.split_hash
    @split_hash = self._split_hash
  end

  private

  def self._split_hash
    if self.test_track_schema_yml.present?
      self.test_track_schema_yml[:splits]
    else
      {}
    end
  end

  def self.test_track_schema_yml
    unless instance_variable_defined?(:@test_track_schema_yml)
      @test_track_schema_yml = self._test_track_schema_yml
    end
    @test_track_schema_yml
  end

  def self._test_track_schema_yml
    YAML.load_file(self.test_track_schema_yml_path).with_indifferent_access
  rescue
    nil
  end

  def self.test_track_schema_yml_path
    ENV["TEST_TRACK_SCHEMA_FILE_PATH"] || "#{Rails.root}/db/test_track_schema.yml"
  end
end
