require 'faraday_middleware'

TestTrack::TestTrackApi = Her::API.new.setup url: ENV['TEST_TRACK_API_URL'] do |c|
  # request
  c.request :json

  # response
  c.use Her::Middleware::DefaultParseJSON

  c.adapter Faraday.default_adapter

  # Set aggressive HTTP timeouts because TestTrack needs to be fast
  c.options[:open_timeout] = ENV['TEST_TRACK_OPEN_TIMEOUT'] || 2 # Number of seconds to wait for the connection to open.
  c.options[:timeout] = ENV['TEST_TRACK_TIMEOUT'] || 4 # Number of seconds to wait for one block to be read (via one read(2) call).
end
