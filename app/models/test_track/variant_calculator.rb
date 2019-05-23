require 'digest'

class TestTrack::VariantCalculator
  include TestTrack::RequiredOptions

  attr_reader :visitor, :split_name

  delegate :split_registry, to: :visitor

  def initialize(opts = {})
    @visitor = require_option!(opts, :visitor)
    @split_name = require_option!(opts, :split_name)
    raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def variant
    return nil unless split_registry.loaded?
    @variant ||= _variant || raise("Assignment bucket out of range. #{assignment_bucket} unmatched in #{split_name}: #{weighting}")
  end

  def _variant
    bucket_ceiling = 0
    sorted_variants.detect do |variant|
      bucket_ceiling += weighting[variant]
      bucket_ceiling > assignment_bucket
    end
  end

  def sorted_variants
    weighting.keys.sort
  end

  def weighting
    @weighting ||= split_registry.weights_for(split_name) ||
      (raise("TestTrack split '#{split_name}' not found. Need to write/run a migration?"))
  end

  def assignment_bucket
    @assignment_bucket ||= hash_fixnum % 100
  end

  def hash_fixnum
    split_visitor_hash.slice(0, 8).to_i(16)
  end

  def split_visitor_hash
    Digest::MD5.new.update(split_name.to_s + visitor.id.to_s).hexdigest
  end
end
