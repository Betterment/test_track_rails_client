module DelayedJobSpecHelper
  def with_jobs_delayed(opts = {})
    work_off = opts.fetch(:work_off, true)
    original = Delayed::Worker.delay_jobs
    Delayed::Worker.delay_jobs = true
    yield
  ensure
    Delayed::Worker.delay_jobs = original
    Delayed::Worker.new.work_off if work_off
  end
end
