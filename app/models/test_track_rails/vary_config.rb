module TestTrackRails
  class VaryConfig
    attr_reader :defaulted, :default_variant
    alias_method :defaulted?, :defaulted

    def initialize(opts)
      def require_option(opt_name)
        opts.delete(opt_name) || raise(ArgumentError, "Must provide #{opt_name}")
      end

      split_name = require_option(:split_name)
      assigned_variant = require_option(:assigned_variant)
      split_registry = require_option(:split_registry)
      raise ArgumentError, "unknown opts: #{opts.keys.to_sentence}" if opts.present?

      @assigned_variant = assigned_variant.to_s
      @split_variants = split_registry[split_name.to_s].keys
      @variant_procs = HashWithIndifferentAccess.new
    end

    def when(*variants)
      raise ArgumentError, "must provide at least one variant" unless variants
      variants.each do |variant|
        assign_proc_to_variant(variant, proc)
      end
    end

    def default(variant)
      raise ArgumentError, "cannot provide more than one `default`" unless default_variant.nil?
      @default_variant = assign_proc_to_variant(variant, proc)
    end

    private

    attr_reader :split_variants, :variant_procs, :assigned_variant

    # VERY TEMPORARY. DON'T DO THIS.
    alias_method :errbit, :puts

    def assign_proc_to_variant(variant, proc)
      variant = variant.to_s

      raise ArgumentError, "must provide block for #{variant}" unless proc.present?
      errbit "\"#{variant}\" is not in split_variants #{split_variants}" unless split_variants.include? variant

      variant_procs[variant] = proc
      variant
    end

    def default_branch
      variant_procs[default_variant]
    end

    def run
      raise ArgumentError, "must provide exactly one `default`" unless default_variant
      raise ArgumentError, "must provide at least one `when`" unless variant_procs.size >= 2
      missing_variants = split_variants - variant_procs.keys
      errbit "#{missing_variants.to_sentence} are missing" unless missing_variants.empty?

      if variant_procs[assigned_variant].present?
        chosen_path = variant_procs[assigned_variant]
      else
        chosen_path = default_branch
        @defaulted = true
      end
      chosen_path.call
    end
  end
end
