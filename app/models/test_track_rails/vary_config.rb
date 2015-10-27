module TestTrackRails
  class VaryConfig
    attr_reader :options, :branches, :assigned_variant_name, :default_variant_name

    def initialize(split_name, assigned_variant_name, split_registry)
      @assigned_variant_name = assigned_variant_name.to_s
      @options = split_registry[split_name.to_s].keys
      @branches = {}
    end

    def when(variant_name, &_block)
      raise ArgumentError, "must provide block to `when` for #{variant_name}" unless block_given?
      _errbit(variant_name) unless options.include? variant_name.to_s

      branches[variant_name.to_s] = proc
    end

    def default(default_variant_name, &_block) # rubocop:disable Metrics/AbcSize
      raise ArgumentError, "must provide block to `default` for #{variant_name}" unless block_given?
      raise ArgumentError, "cannot provide more than one `default`" unless @default.nil?
      _errbit(variant_name) unless @options.include? variant_name.to_s

      @default_variant_name = default_variant_name
      branches[variant_name.to_s] = proc
    end

    private

    def default_branch
      branches[default_variant_name]
    end

    def _errbit(variant_name)
      puts "#{options} must include #{variant_name}" # rubocop:disable Rails/Output
    end

    def _assign_visitor_to_default_variant
      puts "not sure how to do that" # rubocop:disable Rails/Output
    end

    def run
      raise ArgumentError, "must provide exactly one `default`" unless @default
      raise ArgumentError, "must provide at least one `when`" unless @branches.size >= 2

      if branches[assigned_variant_name].present?
        chosen_path = branches[assigned_variant_name]
      else
        chosen_path = default_branch
        _assign_visitor_to_default_variant
      end

      chosen_path.call
    end
  end
end
