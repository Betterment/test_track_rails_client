namespace :test_track do
  desc 'Run outstanding TestTrack migrations'
  task migrate: :environment do
    cli = TesttrackCli.instance
    next if cli.skip_testtrack_cli?

    if cli.project_initialized?
      result = cli.call('migrate')
      exit(result.exitstatus) unless result.success?
    end
  end

  desc 'Generates build timestamp'
  task generate_build_timestamp: :environment do
    cli = TesttrackCli.instance

    result = cli.call('generate_build_timestamp')
    exit(result.exitstatus) unless result.success?
  end

  namespace :schema do
    desc 'Load schema.yml state into TestTrack server'
    task load: :environment do
      cli = TesttrackCli.instance
      next if cli.skip_testtrack_cli?

      if cli.project_initialized?
        result = cli.call('schema', 'load')
        exit(result.exitstatus) unless result.success?
      else
        TestTrack.update_config do |c|
          c.load_schema # Load legacy schema
        end
      end
    end
  end
end

namespace :assets do
  desc 'Sets an environment variable to block build timestamp generation on application initialization'
  task :environment do
    ENV['SKIP_TIMESTAMP_INIT'] = '1'
    Rake::Task["assets:environment"].invoke
  end
end

task 'db:schema:load' => ['test_track:schema:load']
task 'db:structure:load' => ['test_track:schema:load']
task 'db:migrate' => ['test_track:migrate']
task 'assets:precompile' => ['test_track:generate_build_timestamp']

# original = task('assets:environment')
# task('assets:environment').clear
# task('assets:environment') do
#   ENV['SKIP_TIMESTAMP_INIT'] = '1'
#   original.invoke
# end
