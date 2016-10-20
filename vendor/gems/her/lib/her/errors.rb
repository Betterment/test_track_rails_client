module Her
  module Errors
    class PathError < StandardError
      attr_reader :missing_parameter

      def initialize(message, missing_parameter=nil)
        super(message)
        @missing_parameter = missing_parameter
      end
    end

    class AssociationUnknownError < StandardError
    end

    class ResponseError < StandardError
      def self.for(status_code)
        case status_code
          when 404
            RecordNotFound
          when 422
            RecordInvalid
          else
            self
        end
      end
    end

    class ParseError < ResponseError
    end

    class RemoteServerError < ResponseError
    end

    class RecordNotFound < ResponseError
    end

    class RecordInvalid < ResponseError
    end
  end
end
