module Her
  class ErrorCollection
    attr_reader :metadata, :errors

    # @private
    def initialize(metadata={}, errors={})
      @metadata = metadata
      @errors = errors
    end

    def method_missing(method_sym, *arguments, &block)
      raise Her::Errors::ResponseError, "Cannot access collection, Request returned an error"
    end
  end
end
