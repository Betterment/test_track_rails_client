module TestTrack
  class IdentifierCreationJob < ApplicationJob
    def perform(opts)
      Remote::Identifier.create!(opts)
    end
  end
end
