module Her
  module Model
    module ActiveModelOverrides
      extend ActiveSupport::Concern

      def errors
        errors = super
        errors.messages.merge! @response_errors unless @response_errors.empty?
        errors
      end
    end
  end
end
