module EnvironmentSpecHelper
  def with_rails_env(env)
    initial_env = Rails.env
    Rails.env = env
    yield
  ensure
    Rails.env = initial_env
  end
end
