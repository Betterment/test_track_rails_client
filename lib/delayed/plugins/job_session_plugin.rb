module Delayed
    module Plugins
      class JobSessionPlugin < Delayed::Plugin
        callbacks do |lifecycle|
          lifecycle.around(:invoke_job) do |job, *args, &block|
            test_track_job_session = TestTrack::JobSession.new

            test_track_job_session.manage do
              block.call(job, *args)
            end
          end
        end
      end
    end
  end
