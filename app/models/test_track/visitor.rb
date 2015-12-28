class TestTrack::Visitor
  attr_reader :id

  def initialize(opts = {})
    @id = opts.delete(:id)
    @assignment_registry = opts.delete(:assignment_registry)
    @unsynced_splits = opts.delete(:unsynced_splits)
    unless id
      @id = SecureRandom.uuid
      @assignment_registry ||= {} # If we're generating a visitor, we don't need to fetch the assignment_registry
      @unsynced_splits ||= [] # If we're generating a visitor, we don't need to fetch the unsynced_splits
    end
    raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def vary(split_name)
    split_name = split_name.to_s

    raise ArgumentError, "must provide block to `vary` for #{split_name}" unless block_given?
    v = TestTrack::VaryDSL.new(split_name: split_name, assigned_variant: assignment_for(split_name), split_registry: split_registry)
    yield v
    result = v.send :run
    assign_to(split_name, v.default_variant) if v.defaulted?
    result
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
    @assignment_registry ||= remote_visitor && remote_visitor.assignment_registry
  end

  def unsynced_splits
    @unsynced_splits ||= remote_visitor && remote_visitor.unsynced_splits
  end

  def unsynced_assignments
    unless @unsynced_assignments
      if assignment_registry
        unsynced_assignments = assignment_registry.slice(*unsynced_splits)
        @unsynced_assignments = new_assignments.merge(unsynced_assignments)
      else
        @unsynced_assignments = {}
      end
    end
    @unsynced_assignments
  end

  def new_assignments
    @new_assignments ||= {}
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
    remote_identifier_visitor = TestTrack::Remote::IdentifierVisitor.from_identifier(opts[:identifier_type], opts[:identifier_value])
    visitor = new(
      id: remote_identifier_visitor.id,
      assignment_registry: remote_identifier_visitor.assignment_registry,
      unsynced_splits: remote_identifier_visitor.unsynced_splits
    )

    TestTrack::CreateAliasJob.new(existing_mixpanel_id: opts[:existing_mixpanel_id], alias_id: visitor.id).perform
    visitor
  end

  private

  def remote_visitor
    @remote_visitor ||= TestTrack::Remote::Visitor.find(id) unless tt_offline?
  rescue *TestTrack::SERVER_ERRORS
    @tt_offline = true
    nil
  end

  def merge!(other)
    @id = other.id
    new_assignments.except!(*other.assignment_registry.keys)
    assignment_registry.merge!(other.assignment_registry)
    @unsynced_splits = unsynced_splits | other.unsynced_splits # merge other's unsynced splits into ours
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
    assign_to(split_name, TestTrack::VariantCalculator.new(visitor: self, split_name: split_name).variant)
  end

  def assign_to(split_name, variant)
    new_assignments[split_name] = assignment_registry[split_name] = variant unless tt_offline?
  end
end
