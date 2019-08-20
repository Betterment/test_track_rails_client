class TestTrack::VaryDSL
  include TestTrack::RequiredOptions

  attr_reader :defaulted, :default_variant
  alias defaulted? defaulted

  def initialize(opts = {})
    @assignment = require_option!(opts, :assignment)
    @context = require_option!(opts, :context)
    @split_registry = require_option!(opts, :split_registry)
    raise ArgumentError, "unknown opts: #{opts.keys.to_sentence}" if opts.present?

    if @split_registry.loaded? && !split
      raise ArgumentError, "unknown split: #{split_name}." \
        "#{' You may need to run rake test_track:schema:load.' if Rails.env.development?}"
    end
  end

  def when(*variants, &block)
    raise ArgumentError, "must provide at least one variant" if variants.blank?
    variants.each do |variant|
      assign_behavior_to_variant(variant, block)
    end
  end

  def default(variant, &block)
    raise ArgumentError, "cannot provide more than one `default`" unless default_variant.nil?
    @default_variant = assign_behavior_to_variant(variant, block)
  end

  private

  attr_reader :split_registry, :assignment, :context
  delegate :split_name, to: :assignment

  def split
    @split ||= split_registry.weights_for(split_name)
  end

  def split_variants
    @split_variants ||= split.keys if split
  end

  def notify_because_vary(msg)
    misconfiguration_notifier.notify("vary for \"#{split_name}\" #{msg}")
  end

  def misconfiguration_notifier
    @misconfiguration_notifier ||= TestTrack.misconfiguration_notifier
  end

  def variant_behaviors
    @variant_behaviors ||= {}
  end

  def assign_behavior_to_variant(variant, behavior_proc)
    variant = variant.to_s

    raise ArgumentError, "must provide block for #{variant}" unless behavior_proc
    notify_because_vary(<<-MESSAGE) if variant_behaviors.include?(variant)
      configures variant "#{variant}" more than once.
      This will raise an error in the next version of test_track_rails_client.
    MESSAGE
    notify_because_vary "configures unknown variant \"#{variant}\"" unless variant_acceptable?(variant)

    variant_behaviors[variant] = behavior_proc
    variant
  end

  def variant_acceptable?(variant)
    split_variants ? split_variants.include?(variant) : true # If we're flying blind (with no split registry), assume the dev is correct
  end

  def default_proc
    variant_behaviors[default_variant]
  end

  def run # rubocop:disable Metrics/AbcSize
    validate!

    if variant_behaviors[assignment.variant]
      chosen_proc = variant_behaviors[assignment.variant]
    else
      chosen_proc = default_proc
      assignment.variant = default_variant
      @defaulted = true
    end
    assignment.context = context
    chosen_proc.call
  end

  def validate!
    raise ArgumentError, "must provide exactly one `default`" unless default_variant
    raise ArgumentError, "must provide at least one `when`" unless variant_behaviors.size >= 2
    return true unless split_variants
    missing_variants = split_variants - variant_behaviors.keys
    notify_because_vary("does not configure variants #{missing_variants.to_sentence}") && false unless missing_variants.empty?
  end
end
