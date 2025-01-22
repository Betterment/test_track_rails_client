class TestTrack::Assignment
  include TestTrack::RequiredOptions

  attr_accessor :context
  attr_reader :visitor, :split_name
  attr_writer :variant

  def initialize(opts = {})
    @visitor = require_option!(opts, :visitor)
    @split_name = require_option!(opts, :split_name).to_s
    raise ArgumentError, "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def variant
    @variant ||= _variant
  end

  def unsynced?
    true
  end

  def feature_gate?
    split_name.end_with?('_enabled')
  end

  private

  def _variant
    return if visitor.offline?

    variant = TestTrack::VariantCalculator.new(visitor:, split_name:).variant
    variant&.to_s
  end
end
