require 'faraday_middleware'

module TestTrackRails
  TestTrackApi = Her::API.new.setup url: ENV['TEST_TRACK_API_URL'] do |c|
    # request
    c.request :json

    # response
    c.use Her::Middleware::DefaultParseJSON

    c.adapter Faraday.default_adapter
  end
end
