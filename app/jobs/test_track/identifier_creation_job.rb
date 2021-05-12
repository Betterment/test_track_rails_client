module TestTrack
  class IdentifierCreationJob < ApplicationJob
    def perform(identifier_type:, visitor_id:, value:)
      Remote::Identifier.create!(
        identifier_type: identifier_type,
        visitor_id: visitor_id,
        value: value
      )
    end
  end
end
