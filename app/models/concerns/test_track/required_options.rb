module TestTrack::RequiredOptions
  extend ActiveSupport::Concern

  private

  def require_option!(opts, opt_name, my_opts = {})
    opt_provided = my_opts[:allow_nil] ? opts.key?(opt_name) : opts[opt_name]
    raise(ArgumentError, "Must provide #{opt_name}") unless opt_provided

    opts.delete(opt_name)
  end
end
