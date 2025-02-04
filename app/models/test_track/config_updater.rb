class TestTrack::ConfigUpdater
  def initialize(schema_file_path = Rails.root.join('db/test_track_schema.yml'))
    @schema_file_path = schema_file_path
  end

  def split(name, weighting_registry)
    create_split(name, weighting_registry)

    name = name.to_s
    splits.except!(*unpersisted_split_names)
    splits[name] = weighting_registry.stringify_keys

    persist_schema!
  end

  def drop_split(name)
    TestTrack::Remote::SplitConfig.destroy_existing(name)

    splits.except!(name.to_s)

    persist_schema!
  end
  alias finish_split drop_split # to support older migrations written with `finish_split`

  def identifier_type(name)
    create_identifier_type(name)

    identifier_types << name.to_s

    persist_schema!
  end

  def load_schema
    identifier_types.each do |name|
      create_identifier_type(name)
    end

    splits.each do |name, weighting_registry|
      create_split(name, weighting_registry)
    end
  end

  private

  attr_reader :schema_file_path

  def create_split(name, weighting_registry)
    TestTrack::Remote::SplitConfig.new(name:, weighting_registry:).tap do |split_config|
      raise split_config.errors.full_messages.join("\n") unless split_config.save
    end
  end

  def create_identifier_type(name)
    TestTrack::Remote::IdentifierType.new(name:).tap do |identifier_type|
      raise identifier_type.errors.full_messages.join("\n") unless identifier_type.save
    end
  end

  def remote_splits
    unless @remote_splits
      TestTrack::Remote::SplitRegistry.reset
      @remote_splits = TestTrack::Remote::SplitRegistry.to_hash
    end
    @remote_splits
  end

  def persist_schema!
    File.open(schema_file_path, "w") do |f|
      f.write YAML.dump("identifier_types" => identifier_types.sort, "splits" => sorted_splits)
    end
  end

  def identifier_types
    @identifier_types ||= Set.new(schema_file_hash["identifier_types"] || [])
  end

  def unpersisted_split_names
    @unpersisted_split_names ||= splits.keys - remote_splits.keys
  end

  def splits
    @splits ||= schema_file_hash["splits"] || {}
  end

  def sorted_splits
    sorted = Hash[splits.sort]
    sorted.each do |split_name, weighting_registry|
      sorted[split_name] = Hash[weighting_registry.sort]
    end
  end

  def schema_file_hash
    @schema_file_hash ||= YAML.safe_load(schema_file_contents) || {}
  end

  def schema_file_contents
    @schema_file_contents ||= schema_file_exists? ? File.open(schema_file_path, "r").read : ""
  end

  def schema_file_exists?
    File.exist?(schema_file_path)
  end
end
