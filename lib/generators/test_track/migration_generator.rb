require 'rails/generators/base'

module TestTrack
  module Generators
    class MigrationGenerator < Rails::Generators::Base
      IncompatibleOptionsError = Class.new(Thor::Error)

      desc "Creates a test track migration file."

      class_option :type, aliases: 't', type: :string, desc: 'Set up the split as an experiment, gate (feature flag), or drop (finish a split)'

      argument :file_name, required: true

      def create_test_track_migration_file
        validate_options!
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

      def split_class_name
        name = file_name.camelize

        if gate?
          name += 'Enabled'
        elsif experiment?
          name += 'Experiment'
        end

        name
      end

      def full_file_path
        "db/migrate/#{formatted_time_stamp}_#{file_name}.rb"
      end

      def split_command_line
        "#{split_command} :#{split_name}#{split_variants}"
      end

      def formatted_time_stamp
        Time.zone.now.strftime('%Y%m%d%H%M%S')
      end

      def split_command
        @split_command ||= finish_split? ? 'c.drop_split' : 'c.split'
      end

      def split_name
        strip_leading_verb_from_filename + suffix_for_split_type
      end

      def strip_leading_verb_from_filename
        file_name.split('_').slice(1, file_name.length).join('_')
      end

      def suffix_for_split_type
        if gate?
          '_enabled'
        elsif experiment?
          '_experiment'
        else
          ''
        end
      end

      def split_variants
        if finish_split?
          ''
        elsif gate?
          ', true: 0, false: 100'
        elsif experiment?
          ', control: 50, treatment: 50'
        else
          ', control: 100, treatment: 0'
        end
      end

      def validate_options!
        unless %w(experiment gate drop unnamed).include?(split_type)
          raise IncompatibleOptionsError, <<-ERROR.strip_heredoc
            #{split_type} is not a valid split type
          ERROR
        end
      end

      def gate?
        split_type == 'gate'
      end

      def experiment?
        split_type == 'experiment'
      end

      def finish_split?
        split_type == 'drop'
      end

      def split_type
        @split_type ||= options[:type] || 'unnamed'
      end
    end
  end
end
