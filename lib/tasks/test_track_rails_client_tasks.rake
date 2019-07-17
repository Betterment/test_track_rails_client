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

task 'db:schema:load' => ['test_track:schema:load']
task 'db:structure:load' => ['test_track:schema:load']
task 'db:migrate' => ['test_track:migrate']
