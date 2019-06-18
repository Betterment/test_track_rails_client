module TestTrack::MisconfigurationNotifier
  class Wrapper
    attr_reader :underlying

    def initialize(underlying = Null.new)
      @underlying = underlying
    end

    def notify(msg)
      raise msg if Rails.env.development?

      Rails.logger.error(msg)

      underlying.notify(msg)
    end
  end

  class Null
    def notify(_); end
  end

  class Airbrake
    def notify(msg)
      raise "Aibrake was configured not found" unless defined?(::Airbrake)
      if ::Airbrake.respond_to?(:notify_or_ignore)
        ::Airbrake.notify_or_ignore(StandardError.new, error_message: msg)
      else
        ::Airbrake.notify(StandardError.new, error_message: msg)
      end
    end
  end
end
