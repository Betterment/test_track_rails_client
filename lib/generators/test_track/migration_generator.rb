require 'rails/generators/base'

module TestTrack
  module Generators
    class MigrationGenerator < Rails::Generators::Base
      desc "Creates a test track migration file."

      argument :raw_split_name, required: true

      def create_test_track_migration_file
        create_migration_file
      end

      private

      def create_migration_file
        create_file full_file_path, <<-FILE.strip_heredoc
          class #{split_class_name} < ActiveRecord::Migration
            def change
              TestTrack.update_config do |c|
                #{split_command_line}
              end
            end
          end
        FILE
      end

      def split_command_line
        "#{split_command} :#{split_name}#{split_variants}"
      end

      def split_command
        @split_command ||= split_type == :drop ? 'c.drop_split' : 'c.split'
      end

      def split_variants
        case split_type
          when :drop
            ''
          when :gate
            ', true: 0, false: 100'
          when :experiment
            ', control: 50, treatment: 50'
          else
            ', control: 100, treatment: 0'
        end
      end

      def split_type
        if split_file_name.start_with? 'drop'
          :drop
        elsif split_file_name.end_with? 'enabled', 'feature_flag'
          :gate
        elsif split_file_name.end_with? 'experiment'
          :experiment
        else
          :default
        end
      end

      def full_file_path
        "db/migrate/#{formatted_time_stamp}_#{split_file_name}.rb"
      end

      def formatted_time_stamp
        Time.zone.now.strftime('%Y%m%d%H%M%S')
      end

      def split_class_name
        split_file_name.camelize
      end

      def split_name
        noise_words = /^create_|^update_|^drop_|^add_/
        split_file_name.gsub(noise_words, '')
      end

      def split_file_name
        raw_split_name.underscore
      end
    end
  end
end
