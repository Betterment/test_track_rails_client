module TestTrackRails
  class VaryConfig
    attr_reader :options, :branches, :assigned_variant_name, :default_variant_name, :defaulted
    alias_method :defaulted?, :defaulted

    def initialize(split_name, assigned_variant_name, split_registry)
      @assigned_variant_name = assigned_variant_name.to_s
      @options = split_registry[split_name.to_s].keys
      @branches = HashWithIndifferentAccess.new
    end

    def when(*variant_names)
      variant_names.each do |variant_name|
        raise ArgumentError, "must provide block to `when` for #{variant_name}" unless block_given?
        errbit(variant_name) unless options.include? variant_name.to_s

        branches[variant_name.to_s] = proc
      end
    end

    def default(variant_name) # rubocop:disable Metrics/AbcSize
      raise ArgumentError, "cannot provide more than one `default`" unless default_variant_name.nil?

      raise ArgumentError, "must provide block to `default` for #{variant_name}" unless block_given?
      errbit(default_variant_name) unless options.include? variant_name.to_s

      @default_variant_name = variant_name.to_s
      branches[variant_name.to_s] = proc
    end

    private

    def default_branch
      branches[default_variant_name]
    end

    def errbit(variant_name)
      puts "#{options} must include #{variant_name}" # rubocop:disable Rails/Output
    end

    def run # rubocop:disable Metrics/AbcSize
      raise ArgumentError, "must provide exactly one `default`" unless default_variant_name
      raise ArgumentError, "must provide at least one `when`" unless branches.size >= 2

      if branches[assigned_variant_name].present?
        chosen_path = branches[assigned_variant_name]
      else
        chosen_path = default_branch
        @defaulted = true
      end

      chosen_path.call
    end
  end
end
