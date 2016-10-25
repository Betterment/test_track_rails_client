Airbrake.configure do |config|
  if config.respond_to?(:api_key=)
    config.api_key = '00112233445566778899aabbccddeeff'
  else
    config.project_id = "1234567890"
    config.project_key = "00112233445566778899aabbccddeeff"
  end

  if config.respond_to?(:port)
    config.host    = 'errbit.dev'
    config.port    = 80
    config.secure  = config.port == 443
  else
    config.host = "http://errbit.dev"
  end

  if config.respond_to?(:ignore_environments)
    config.environment = "test"
    config.ignore_environments = %w(test development)
  else
    config.environment_name = "test"
    config.development_environments = %w(test development)
  end
end

unless Delayed::Worker.plugins.include?(Delayed::Plugins::Airbrake)
  Delayed::Worker.plugins << Delayed::Plugins::Airbrake::Plugin
end
