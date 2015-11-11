class TestTrack::ConfigUpdater
  def split(name, weighting_registry)
    TestTrack::SplitConfig.create!(name: name, weighting_registry: weighting_registry)
    splits[name.to_s] = weighting_registry.stringify_keys
    persist_schema!
  end

  def identifier_type(name)
    TestTrack::IdentifierType.create!(name: name)
    identifier_types << name.to_s
    persist_schema!
  end

  private

  def persist_schema!
    file = File.open(schema_file_name, "w")
    YAML.dump({ "identifier_types" => identifier_types.to_a, "splits" => splits }, file)
  end

  def identifier_types
    @identifier_types ||= Set.new(schema_file_hash["identifier_types"] || [])
  end

  def splits
    @splits ||= schema_file_hash["splits"] || {}
  end

  def schema_file_hash
    @schema_hash ||= YAML.load(schema_file_contents) || {}
  end

  def schema_file_contents
    @schema_file_contents ||= File.open(schema_file_name, "a+").read
  end

  def schema_file_name
    @schema_file_name ||= "#{Rails.root}/db/test_track_schema.yml"
  end
end
