class TestTrack::ABConfiguration
  include TestTrack::RequiredOptions

  def initialize(opts)
    split_name = require_option!(opts, :split_name)
    true_variant = require_option!(opts, :true_variant, allow_nil: true)
    split_registry = require_option!(opts, :split_registry, allow_nil: true)
    raise ArgumentError, "unknown opts: #{opts.keys.to_sentence}" if opts.present?

    @split_name = split_name.to_s
    @true_variant = true_variant.to_s if true_variant

    ensure_split_exists!(@split_name, split_registry)
    @split_variants = split_registry[@split_name].keys if split_registry
  end

  def variants
    @variants ||= build_variant_hash
  end

  private

  def build_variant_hash
    airbrake_because_ab("configures split with more than 2 variants") if split_variants && split_variants.size > 2
    { true: true_variant, false: false_variant }
  end

  def true_variant
    @true_variant ||= true
  end

  def false_variant
    @false_variant ||= non_true_variants.present? ? non_true_variants.sort.first : false
  end

  attr_reader :split_name, :split_variants

  def non_true_variants
    split_variants - [true_variant.to_s] if split_variants
  end

  def airbrake_because_ab(msg)
    msg = "A/B for \"#{split_name}\" #{msg}"
    Rails.logger.error(msg)
    Airbrake.notify_or_ignore(msg)
  end

  def ensure_split_exists!(split_name, split_registry)
    raise ArgumentError, "unknown split: #{split_name}" if split_registry && !split_registry[split_name]
  end
end
