namespace :test_track do
  namespace :schema do
    desc 'Load all Identifier Types and Splits into TestTrack from the schema file'
    task load: :environment do
      TestTrack.update_config do |c|
        c.load_schema
      end
    end
  end
end

task 'db:schema:load' => ['test_track:schema:load']
task 'db:structure:load' => ['test_track:schema:load']
