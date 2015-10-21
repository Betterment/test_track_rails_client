require 'digest'

module TestTrackRails
  class VariantCalculator
    attr_reader :visitor, :split_name

    delegate :split_registry, to: :visitor

    def initialize(opts = {})
      @visitor = opts.delete(:visitor)
      raise "Must provide visitor" unless visitor
      @split_name = opts.delete(:split_name)
      raise "Must provide split_name" unless split_name
      raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
    end

    def variant
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
      @weighting ||= split_registry[split_name]
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
end
