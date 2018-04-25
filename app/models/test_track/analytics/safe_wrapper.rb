module TestTrack::Analytics
  class SafeWrapper
    attr_reader :underlying

    def initialize(underlying)
      @underlying = underlying
    end

    def error_handler=(handler)
      raise ArgumentError, "error_handler must be a lambda" unless handler.lambda?
      raise ArgumentError, "error_handler must accept 1 argument" unless handler.arity == 1
      @error_handler = handler
    end

    def track(analytics_event)
      safe_action { underlying.track(analytics_event) }
    end

    def sign_up!(visitor_id)
      safe_action { underlying.sign_up!(visitor_id) } if underlying.respond_to?(:sign_up!)
    end

    private

    def error_handler
      @error_handler || ->(e) do
        Rails.logger.error e
      end
    end

    def safe_action
      yield
      true
    rescue StandardError => e
      error_handler.call e
      false
    end
  end
end
