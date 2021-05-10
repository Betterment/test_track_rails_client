module TestTrack
  class IdentifierCreationJob < TestTrack.job_base_class_name.constantize
    def perform(opts)
      Remote::Identifier.create!(opts)
    end
  end
end
