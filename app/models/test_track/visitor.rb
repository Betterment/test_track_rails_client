class TestTrack::Visitor
  attr_reader :id

  def initialize(opts = {})
    @id = opts.delete(:id)
    @assignments = opts.delete(:assignments)
    unless id
      @id = SecureRandom.uuid
      @assignments ||= [] # If we're generating a visitor, we don't need to fetch the assignments
    end
    raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def vary(split_name)
    split_name = split_name.to_s

    raise ArgumentError, "must provide block to `vary` for #{split_name}" unless block_given?
    v = TestTrack::VaryDSL.new(assignment: assignment_for(split_name), split_registry: split_registry)
    yield v
    v.send :run
  end

  def ab(split_name, true_variant = nil)
    split_name = split_name.to_s

    ab_configuration = TestTrack::ABConfiguration.new split_name: split_name, true_variant: true_variant, split_registry: split_registry

    vary(split_name) do |v|
      v.when ab_configuration.variants[:true] do
        true
      end
      v.default ab_configuration.variants[:false] do
        false
      end
    end
  end

  def assignment_registry
    @assignment_registry ||= assignments.each_with_object({}) do |assignment, hsh|
      hsh[assignment.split_name] = assignment
    end
  end

  def unsynced_assignments
    @unsynced_assignments ||= assignment_registry.values.select(&:unsynced?)
  end

  def assignment_json
    assignment_registry.values.each_with_object({}) do |assignment, hsh|
      hsh[assignment.split_name] = assignment.variant
    end
  end

  def split_registry
    @split_registry ||= TestTrack::Remote::SplitRegistry.to_hash
  end

  def link_identifier!(identifier_type, identifier_value)
    identifier_opts = { identifier_type: identifier_type, visitor_id: id, value: identifier_value.to_s }
    begin
      identifier = TestTrack::Remote::Identifier.create!(identifier_opts)
      merge!(identifier.visitor)
    rescue *TestTrack::SERVER_ERRORS
      # If at first you don't succeed, async it - we may not display 100% consistent UX this time,
      # but subsequent requests will be better off
      TestTrack::Remote::Identifier.delay.create!(identifier_opts)
    end
  end

  def self.backfill_identity(opts)
    remote_identifier_visitor = TestTrack::Remote::Visitor.from_identifier(opts[:identifier_type], opts[:identifier_value])
    visitor = new(
      id: remote_identifier_visitor.id,
      assignments: remote_identifier_visitor.assignments
    )

    TestTrack::CreateAliasJob.new(existing_mixpanel_id: opts[:existing_mixpanel_id], alias_id: visitor.id).perform
    visitor
  end

  def offline?
    @tt_offline
  end

  private

  def assignments
    @assignments ||= (remote_visitor && remote_visitor.assignments) || []
  end

  def remote_visitor
    @remote_visitor ||= TestTrack::Remote::Visitor.find(id) unless tt_offline?
  rescue *TestTrack::SERVER_ERRORS
    @tt_offline = true
    nil
  end

  def merge!(other)
    @id = other.id
    @assignment_registry = assignment_registry.merge(other.assignment_registry)
    @unsynced_assignments = nil
  end

  def tt_offline?
    @tt_offline || false
  end

  def assignment_for(split_name)
    fetch_assignment_for(split_name) || generate_assignment_for(split_name)
  end

  def fetch_assignment_for(split_name)
    assignment_registry[split_name] if assignment_registry
  end

  def generate_assignment_for(split_name)
    assignment_registry[split_name] = TestTrack::Assignment.new(self, split_name)
  end
end
