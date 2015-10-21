module TestTrackRails
  class Visitor
    attr_reader :id

    def initialize(opts = {})
      @id = opts.delete(:id)
      unless id
        @id = SecureRandom.uuid
        @assignment_registry = {} # If we're generating a visitor, we don't need to fetch the registry
      end
      raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
    end

    def assignment_for(split_name)
      split_name = split_name.to_s
      coerce_booleans(assignment_registry[split_name] || generate_assignment_for(split_name))
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

    private

    def generate_assignment_for(split_name)
      variant = VariantCalculator.new(visitor: self, split_name: split_name).variant
      new_assignments[split_name] = variant
      assignment_registry[split_name] = variant
    end

    def coerce_booleans(str)
      case str
        when "true"
          true
        when "false"
          false
        else
          str
      end
    end
  end
end
