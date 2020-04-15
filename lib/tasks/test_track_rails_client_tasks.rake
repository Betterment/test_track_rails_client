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

  desc 'Generates build timestamp for fetching point-in-time split registries'
  task generate_build_timestamp: :environment do
    cli = TesttrackCli.instance

    result = cli.call('generate_build_timestamp')
    exit(result.exitstatus) unless result.success?
  end

  desc 'Sets an environment variable to block build timestamp generation on application initialization'
  task :skip_load_build_timestamp do # rubocop:disable Rails/RakeEnvironment
    ENV['SKIP_TESTTRACK_SET_BUILD_TIMESTAMP'] = '1'
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

task 'assets:environment' => ['test_track:skip_load_build_timestamp']
task 'assets:precompile' => ['test_track:generate_build_timestamp']
task 'db:schema:load' => ['test_track:schema:load']
task 'db:structure:load' => ['test_track:schema:load']
task 'db:migrate' => ['test_track:migrate']
