module TestTrackRails
  class Visitor
    attr_reader :id

    def initialize(opts = {})
      @id = opts.delete(:id)
      @assignment_registry = opts.delete(:assignment_registry)
      unless id
        @id = SecureRandom.uuid
        @assignment_registry ||= {} # If we're generating a visitor, we don't need to fetch the registry
      end
      raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
    end

    def vary(split_name)
      split_name = split_name.to_s

      raise ArgumentError, "must provide block to `vary` for #{split_name}" unless block_given?
      v = VaryDSL.new(split_name: split_name, assigned_variant: assignment_for(split_name), split_registry: split_registry)
      yield v
      result = v.send :run
      assign_to(split_name, v.default_variant) if v.defaulted?
      result
    end

    def assignment_registry
      @assignment_registry ||= TestTrackRails::AssignmentRegistry.for_visitor(id).attributes
    end

    def new_assignments
      @new_assignments ||= {}
    end

    def split_registry
      @split_registry ||= SplitRegistry.to_hash
    end

    def log_in!(identifier_type, identifier)
      identifier_opts = { identifier_type: identifier_type, visitor_id: id, value: identifier.to_s }
      begin
        identifier = Identifier.create!(identifier_opts)
        merge!(identifier.visitor)
      rescue Faraday::TimeoutError
        # If at first you don't succeed, async it - we may not display 100% consistent UX this time,
        # but subsequent requests will be better off
        Identifier.delay.create!(identifier_opts)
      end
      self
    end

    alias_method :sign_up!, :log_in!

    private

    def merge!(other)
      @id = other.id
      new_assignments.except!(*other.assignment_registry.keys)
      assignment_registry.merge!(other.assignment_registry)
    end

    def assignment_for(split_name)
      assignment_registry[split_name] || generate_assignment_for(split_name)
    end

    def assign_to(split_name, variant)
      new_assignments[split_name] = assignment_registry[split_name] = variant
    end

    def generate_assignment_for(split_name)
      assign_to(split_name, VariantCalculator.new(visitor: self, split_name: split_name).variant)
    end
  end
end
