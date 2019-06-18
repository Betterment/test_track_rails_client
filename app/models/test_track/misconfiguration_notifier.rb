module TestTrack::MisconfigurationNotifier
  class Wrapper
    attr_reader :notifier

    def initialize(notifier = Null.new)
      @notifier = notifier
    end

    def notify(msg)
      raise msg if Rails.env.development?

      Rails.logger.error(msg)

      notifier.notify(msg)
    end
  end

  class Null
    def notify(_)
    end
  end

  class Airbrake
    def notify(msg)
      if defined?(::Airbrake)
        if ::Airbrake.respond_to?(:notify_or_ignore)
          ::Airbrake.notify_or_ignore(StandardError.new, error_message: msg)
        else
          ::Airbrake.notify(StandardError.new, error_message: msg)
        end
      end
    end
  end
end
