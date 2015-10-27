module TestTrackRails
  class VaryConfig
    def initialize(split_name, assignment, split_registry)
      @options = split_registry[split_name.to_s].keys
      @assignment = assignment.to_s
      @branches = {}
    end

    def when(assignment_name, &_block)
      raise ArgumentError, "must provide block to `when` for #{assignment_name}" unless block_given?
      _errbit(assignment_name) unless @options.include? assignment_name.to_s

      @branches[assignment_name.to_s] = proc
    end

    def default(assignment_name, &_block)
      raise ArgumentError, "must provide block to `default` for #{assignment_name}" unless block_given?
      _errbit(assignment_name) unless @options.include? assignment_name.to_s
      raise ArgumentError, "cannot provide more than one `default`" unless @default.nil?

      @default = assignment_name
      @branches[assignment_name.to_s] = proc
    end

    private

    def _errbit(assignment_name)
      puts "#{@options} must include #{assignment_name}" # rubocop:disable Rails/Output
    end

    def run
      raise ArgumentError, "must provide exactly one `default`" unless @default
      raise ArgumentError, "must provide at least one `when`" unless @branches.size >= 2

      chosen_path = @branches[@assignment].nil? ? @branches[@default] : @branches[@assignment]
      chosen_path.call
    end
  end
end
