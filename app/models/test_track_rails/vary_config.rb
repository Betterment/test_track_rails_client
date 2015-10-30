module TestTrackRails
  class VaryConfig
    attr_reader :defaulted, :default_variant
    alias_method :defaulted?, :defaulted

    def initialize(opts)
      split_name = opts.delete(:split_name)
      raise ArgumentError, "Must provide split_name" unless split_name
      assigned_variant = opts.delete(:assigned_variant)
      raise ArgumentError, "Must provide assigned_variant" unless assigned_variant
      split_registry = opts.delete(:split_registry)
      raise ArgumentError, "Must provide split_registry" unless split_registry
      raise ArgumentError, "unknown opts: #{opts.keys.to_sentence}" if opts.present?

      @assigned_variant = assigned_variant.to_s
      @options = split_registry[split_name.to_s].keys
      @branches = HashWithIndifferentAccess.new
    end

    def when(*variants)
      variants.each do |variant|
        raise ArgumentError, "must provide block to `when` for #{variant}" unless block_given?
        errbit "\"#{variant}\" is not in options #{options}" unless options.include? variant.to_s

        branches[variant.to_s] = proc
      end
    end

    def default(variant)
      raise ArgumentError, "cannot provide more than one `default`" unless default_variant.nil?
      raise ArgumentError, "must provide block to `default` for #{variant}" unless block_given?
      errbit "\"#{variant}\" is not in options #{options}" unless options.include? variant.to_s

      @default_variant = variant.to_s
      branches[variant.to_s] = proc
    end

    private

    attr_reader :options, :branches, :assigned_variant

    def default_branch
      branches[default_variant]
    end

    alias_method :errbit, :puts

    def run
      raise ArgumentError, "must provide exactly one `default`" unless default_variant
      raise ArgumentError, "must provide at least one `when`" unless branches.size >= 2
      missing_variants = options - branches.keys
      errbit "#{missing_variants.to_sentence} are missing" unless missing_variants.empty?

      if branches[assigned_variant].present?
        chosen_path = branches[assigned_variant]
      else
        chosen_path = default_branch
        @defaulted = true
      end
      chosen_path.call
    end
  end
end
