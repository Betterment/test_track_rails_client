class TestTrack::MisconfigurationNotifier
  def notify(msg)
    Rails.logger.error(msg)

    if Airbrake.respond_to?(:notify_or_ignore)
      Airbrake.notify_or_ignore(msg)
    else
      Airbrake.notify(msg)
    end
  end
end
