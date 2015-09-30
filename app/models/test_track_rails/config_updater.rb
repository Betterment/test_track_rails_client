module TestTrackRails
  class ConfigUpdater
    def split(name, weighting_registry)
      SplitConfig.create!(name: name, weighting_registry: weighting_registry)
    end

    def identifier_type(name)
      IdentifierType.create!(name: name)
    end
  end
end
