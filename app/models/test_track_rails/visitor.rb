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

    class Variation
      def initialize(split_name, assignment, split_registry)
        @options = split_registry[split_name.to_s].keys
        @assignment = assignment.to_s
        @branches = {}
      end

      def when(assignment_name, &block)
        raise ArgumentError, "must provide block to `when` for #{assignment_name}" unless block_given?
        raise ArgumentError, "#{@options} must include #{assignment_name}" unless @options.include? assignment_name.to_s

        @branches[assignment_name.to_s] = proc
      end

      def default(assignment_name, &block)
        raise ArgumentError, "must provide block to `default` for #{assignment_name}" unless block_given?
        raise ArgumentError, "#{@options} must include #{assignment_name}" unless @options.include? assignment_name.to_s
        raise ArgumentError, "cannot provide more than one `default`" unless @default.nil?

        @default = assignment_name
        @branches[assignment_name.to_s] = proc
      end

      def run
        raise ArgumentError, "must provide exactly one `default`" unless @default
        raise ArgumentError, "must provide at least one `when`" unless @branches.size >= 2

        chosen_path = @branches[@assignment].nil? ? @branches[@default] : @branches[@assignment]
        chosen_path.call
      end
    end

    def vary(split_name)
      raise ArgumentError, "must provide block to `vary` for #{split_name}" unless block_given?
      v = Variation.new(split_name, assignment_for(split_name), split_registry)
      yield v
      v.run
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

    private

    def merge!(other)
      @id = other.id
      new_assignments.except!(*other.assignment_registry.keys)
      assignment_registry.merge!(other.assignment_registry)
    end 

    def assignment_for(split_name)
      split_name = split_name.to_s
      coerce_booleans(assignment_registry[split_name] || generate_assignment_for(split_name))
    end

    def generate_assignment_for(split_name)
      VariantCalculator.new(visitor: self, split_name: split_name).variant.tap do |v|
        new_assignments[split_name] = assignment_registry[split_name] = v
      end
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
