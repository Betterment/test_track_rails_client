class TestTrack::CreateAliasJob
  attr_reader :existing_id, :alias_id

  def initialize(opts)
    @existing_id = opts.delete(:existing_id)
    @alias_id = opts.delete(:alias_id)

    %w(existing_id alias_id).each do |param_name|
      raise "#{param_name} must be present" unless send(param_name).present?
    end
    raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def perform
    return unless TestTrack.enabled?
    TestTrack.analytics.alias(alias_id, existing_id)
  end
end
