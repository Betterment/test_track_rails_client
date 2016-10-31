require 'rails/generators/base'

module TestTrack
  module Generators
    class MigrationGenerator < Rails::Generators::Base
      IncompatibleOptionsError = Class.new(Thor::Error)

      desc "Creates a test track migration file. Files that start with retire or finish will create migrations that finish a split."

      class_option :experiment, aliases: 'e', type: :boolean, desc: 'Set up the split as an experiment'
      class_option :gate, aliases: 'g', type: :boolean, desc: 'Set up the split as a gate/feature flag'

      argument :file_name, required: true

      def create_test_track_migration_file
        validate_options!
        create_migration_file
      end

      private

      def create_migration_file
        create_file "db/migrate/#{formatted_time_stamp}_#{file_name}.rb", <<-FILE.strip_heredoc
          class #{file_name.camelize} < ActiveRecord::Migration
            def change
              TestTrack.update_config do |c|
                #{split_command_line}
              end
            end
          end
        FILE
      end

      def split_command_line
        "#{split_command} :#{split_name}, #{split_variants}"
      end

      def formatted_time_stamp
        Time.now.strftime('%Y%m%d%H%M%S')
      end

      def split_command
        @split_command ||= finish_split? ? 'c.finish_split' : 'c.split'
      end

      def finish_split?
        file_name.start_with?('retire', 'finish')
      end

      def split_name
        name = file_name.split('_').slice(1, file_name.length).join('_')
        if gate?
          name += '_enabled'
        elsif experiment?
          name += '_experiment'
        end
        name
      end

      def split_variants
        if gate?
          'true: 0, false: 100'
        elsif experiment?
          'control: 50, treatment: 50'
        else
          'control: 100, treatment: 0'
        end
      end

      def validate_options!
        raise IncompatibleOptionsError, <<-ERROR.strip_heredoc
          --gate and --experiment cannot be used together. Please choose one or the other.
        ERROR
      end

      def gate?
        options[:gate].present?
      end

      def experiment?
        options[:experiment].present?
      end
    end
  end
end
