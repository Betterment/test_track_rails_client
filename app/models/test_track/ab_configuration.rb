class TestTrack::ABConfiguration
  include TestTrack::RequiredOptions

  def initialize(opts)
    @split_name = require_option!(opts, :split_name).to_s
    true_variant = require_option!(opts, :true_variant, allow_nil: true)
    @split_registry = require_option!(opts, :split_registry, allow_nil: true)
    raise ArgumentError, "unknown opts: #{opts.keys.to_sentence}" if opts.present?

    @true_variant = true_variant.to_s if true_variant

    raise ArgumentError, "unknown split: #{split_name}" if @split_registry && !split
  end

  def variants
    @variants ||= build_variant_hash
  end

  private

  def build_variant_hash
    notify_because_ab("configures split with more than 2 variants") if split_variants && split_variants.size > 2
    { true: true_variant, false: false_variant }
  end

  def true_variant
    @true_variant ||= true
  end

  def false_variant
    @false_variant ||= non_true_variants.present? ? non_true_variants.sort.first : false
  end

  attr_reader :split_name, :split_registry

  def split
    split_registry && split_registry[split_name]
  end

  def split_variants
    @split_variants ||= split.keys if split_registry
  end

  def non_true_variants
    split_variants - [true_variant.to_s] if split_variants
  end

  def notify_because_ab(msg)
    misconfiguration_notifier.notify("A/B for \"#{split_name}\" #{msg}")
  end

  def misconfiguration_notifier
    @misconfiguration_notifier ||= TestTrack::MisconfigurationNotifier.new
  end
end
