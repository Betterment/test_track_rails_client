class TestTrack::VaryDSL
  include TestTrack::RequiredOptions

  attr_reader :defaulted, :default_variant
  alias_method :defaulted?, :defaulted

  def initialize(opts)
    split_name = require_option!(opts, :split_name)
    assigned_variant = require_option!(opts, :assigned_variant, allow_nil: true)
    split_registry = require_option!(opts, :split_registry, allow_nil: true)
    raise ArgumentError, "unknown opts: #{opts.keys.to_sentence}" if opts.present?

    @split_name = split_name.to_s
    @assigned_variant = assigned_variant.to_s if assigned_variant
    @split_variants = split_registry[split_name.to_s].keys if split_registry
  end

  def when(*variants)
    raise ArgumentError, "must provide at least one variant" unless variants.present?
    variants.each do |variant|
      assign_proc_to_variant(variant, Proc.new)
    end
  end

  def default(variant)
    raise ArgumentError, "cannot provide more than one `default`" unless default_variant.nil?
    @default_variant = assign_proc_to_variant(variant, Proc.new)
  end

  private

  attr_reader :split_name, :split_variants, :assigned_variant

  def airbrake_because_vary(msg)
    Rails.logger.error(msg)
    Airbrake.notify_or_ignore("vary for \"#{split_name}\" #{msg}")
  end

  def variant_procs
    @variant_procs ||= {}
  end

  def assign_proc_to_variant(variant, proc)
    variant = variant.to_s

    raise ArgumentError, "must provide block for #{variant}" unless proc
    airbrake_because_vary "configures unknown variant \"#{variant}\"" unless variant_acceptable?(variant)

    variant_procs[variant] = proc
    variant
  end

  def variant_acceptable?(variant)
    split_variants ? split_variants.include?(variant) : true # If we're flying blind (with no split registry), assume the dev is correct
  end

  def default_proc
    variant_procs[default_variant]
  end

  def run
    validate!

    if variant_procs[assigned_variant]
      chosen_proc = variant_procs[assigned_variant]
    else
      chosen_proc = default_proc
      @defaulted = true
    end
    chosen_proc.call
  end

  def validate!
    raise ArgumentError, "must provide exactly one `default`" unless default_variant
    raise ArgumentError, "must provide at least one `when`" unless variant_procs.size >= 2
    return true unless split_variants
    missing_variants = split_variants - variant_procs.keys
    airbrake_because_vary("does not configure variants #{missing_variants.to_sentence}") && false unless missing_variants.empty?
  end
end
