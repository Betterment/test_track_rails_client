require 'her'
require 'active_support/concern'
require 'rails'

module FakeableHer
  module Model
    extend ActiveSupport::Concern
    include Her::Model

    def save
      if valid?
        if self.class.faked?
          callback = new? ? :create : :update

          run_callbacks callback do
            run_callbacks :save do
              response_attrs = fake_save_response_attributes
              assign_attributes(response_attrs) if response_attrs.present?

              if self.changed_attributes.present?
                @previously_changed = self.changed_attributes.clone
                self.changed_attributes.clear
              end
            end
          end
          true
        else
          super
        end
      else
        false
      end
    end

    def destroy
      if self.class.faked?
        run_callbacks :destroy do
          @destroyed = true
          freeze
        end
      else
        super
      end
    end

    def fake_save_response_attributes
      raise "You must define `#fake_save_response_attributes` to provide default values for #{self.class.name} during development. For more details, refer to the Retail app README."
    end

    unless method_defined?(:clear_changes_information)
      def clear_changes_information
        if respond_to?(:reset_changes)
          reset_changes
        else
          @previously_changed = ActiveSupport::HashWithIndifferentAccess.new
          @changed_attributes = ActiveSupport::HashWithIndifferentAccess.new
        end
      end
    end

    private :clear_changes_information

    module ClassMethods
      def faked?
        !ENV["#{service_name.to_s.upcase}_ENABLED"] && (Rails.env.development? || Rails.env.test?)
      end

      def fake_instance_attributes(id)
        raise "You must define `.fake_instance_attributes` to provide default values for #{self.name} during development. For more details, refer to the Retail app README."
      end

      def fake_collection_attributes(params = {})
        raise "You must define `.fake_collection_attributes` to provide default values for #{self.name} during development. For more details, refer to the Retail app README."
      end

      def service_name
        raise "You must define `.service_name` (e.g. :institutional) for #{self.name} to express which HTTP service may be faked."
      end

      #TODO: move this into a more proper location
      def create!(*args, &block)
        create(*args, &block).tap do |instance|
          raise "Remote model failed to save" if instance.response_errors.present? || instance.errors.present? || instance.invalid?
        end
      end

      def destroy_existing(id, params = {}, headers = {})
        if faked?
          new(_destroyed: true)
        else
          super id, params, headers
        end
      end

      private

      def blank_relation
        FakeableRelation.new(self)
      end
    end

    class FakeableRelation < Her::Model::Relation
      def fetch
        if @parent.faked?
          fetch_collection
        else
          super
        end
      end

      def first
        if @parent.faked?
          _first
        else
          super
        end
      end

      def find(*ids)
        if @parent.faked?
          args = ids
          args << @params if @params.present?
          @parent.new(@parent.fake_instance_attributes(*args)).tap { |p| p.send(:clear_changes_information) }
        else
          super
        end
      end

      private

      def _first
        id_param = @params[@parent.primary_key]

        if id_param && !id_param.is_a?(Array)
          @params.delete(@parent.primary_key)
          @parent.new(@parent.fake_instance_attributes(id_param, @params)).tap { |p| p.send(:clear_changes_information) }
        else
          fetch_collection.first
        end
      end

      def fetch_collection
        Her::Collection.new @parent.fake_collection_attributes(@params).map { |attrs| @parent.new(attrs).tap { |p| p.send(:clear_changes_information) } }
      end
    end
  end
end

