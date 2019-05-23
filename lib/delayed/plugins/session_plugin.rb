module Delayed
    module Plugins
      class SessionPlugin < Delayed::Plugin
        callbacks do |lifecycle|
          lifecycle.around(:invoke_job) do |job, *args, &block|
            test_track_background_session = TestTrack::BackgroundSession.new
            RequestStore[:test_track_background_session] = test_track_background_session

            test_track_background_session.manage do
              block.call(job, *args)
            end
          end
        end
      end
    end
  end
