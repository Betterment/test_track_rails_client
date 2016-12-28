class TestTrack::MisconfigurationNotifier
  def notify(msg)
    raise msg if Rails.env.development?

    Rails.logger.error(msg)

    if Airbrake.respond_to?(:notify_or_ignore)
      Airbrake.notify_or_ignore(StandardError.new, error_message: msg)
    else
      Airbrake.notify(StandardError.new, error_message: msg)
    end
  end
end
