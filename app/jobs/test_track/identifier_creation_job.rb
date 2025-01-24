module TestTrack
  class IdentifierCreationJob < ApplicationJob
    def perform(identifier_type:, visitor_id:, value:)
      Remote::Identifier.create!(
        identifier_type:,
        visitor_id:,
        value:
      )
    end
  end
end
