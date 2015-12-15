class TestTrack::Visitor
  include TestTrack::TestTrackModel

  attr_reader :id

  def initialize(opts = {})
    super opts
    @id = opts.delete(:id)
    @assignment_registry = opts.delete(:assignment_registry)
    unless id
      @id = SecureRandom.uuid
      @assignment_registry ||= {} # If we're generating a visitor, we don't need to fetch the registry
    end
    raise "unknown opts: #{opts.keys.to_sentence}" if opts.present?
  end

  def self.fake_instance_attributes(_)
    {
      id: "fake_visitor_id",
      assignment_registry: {
        time: 'hammertime'
      }
    }
  end

  def self.for_identifier(identifier_type_name, identifier_value)
    raise "must provide an identifier_type_name" unless identifier_type_name.present?
    raise "must provide an identifier_value" unless identifier_value.present?

    # TODO: FakeableHer needs to make this faking a feature of `get`
    if ENV['TEST_TRACK_ENABLED']
      get("/api/identifier_types/#{identifier_type_name}/identifiers/#{identifier_value}/visitor")
    else
      new(fake_instance_attributes(nil))
    end
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
    @assignment_registry ||= TestTrack::AssignmentRegistry.for_visitor(id).attributes unless tt_offline?
  rescue *TestTrack::SERVER_ERRORS
    @tt_offline = true
    nil
  end

  def new_assignments
    @new_assignments ||= {}
  end

  def split_registry
    @split_registry ||= TestTrack::SplitRegistry.to_hash
  end

  def merge!(other)
    @id = other.id
    new_assignments.except!(*other.assignment_registry.keys)
    assignment_registry.merge!(other.assignment_registry)
  end

  private

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
