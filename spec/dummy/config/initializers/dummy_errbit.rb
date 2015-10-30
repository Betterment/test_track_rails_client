if ENV['ERRBIT_ENABLED'] == 'true'
  Airbrake.configure do |config|
    config.api_key = '00112233445566778899aabbccddeeff'
    config.host    = 'errbit.dev'
    config.port    = 80
    config.secure  = config.port == 443
  end

  Delayed::Worker.plugins << Delayed::Plugins::Airbrake::Plugin
end
