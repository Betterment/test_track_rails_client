require 'rails/generators/named_base'

module TestTrack
  module Generators
    class MigrationGenerator < Rails::Generators::NamedBase
      desc "Creates a test track migration file. " \
        "Files that start with retire or finish will create migrations" \
        "that finish a split"

      def create_test_track_migration_file
        create_file "db/migrate/#{formatted_time_stamp}_#{file_name}.rb", <<-FILE.strip_heredoc
          class #{file_name.camelize} < ActiveRecord::Migration
            def change
              TestTrack.update_config do |c|
                #{split_command} :#{split_name}
              end
            end
          end
        FILE
      end

      private

      def formatted_time_stamp
        Time.zone.now.strftime('%Y%m%d%H%M%S')
      end

      def split_command
        @split_command ||= finish_split? ? 'c.finish_split' : 'c.split'
      end

      def finish_split?
        file_name.start_with?('retire', 'finish')
      end

      def split_name
        file_name.split('_').slice(1, file_name.length).join('_')
      end
    end
  end
end
