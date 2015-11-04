class TestTrack::ConfigUpdater
  def split(name, weighting_registry)
    TestTrack::SplitConfig.create!(name: name, weighting_registry: weighting_registry)
  end

  def identifier_type(name)
    TestTrack::IdentifierType.create!(name: name)
  end
end
