require 'faraday'
require 'faraday/request/json'
require 'faraday/response/json'
require 'faraday/response/raise_error'

module TestTrack
  module Client
    extend self # rubocop:disable Style/ModuleFunction

    attr_writer :connection

    def fake?
      !TestTrack.enabled?
    end

    def request(method:, path:, fake:, body: nil, headers: nil)
      # Ensure that fake responses are consistent with real responses
      return JSON.parse(JSON.generate(fake)) if fake?

      response = connection.run_request(method, path, body, headers)
      response.body
    end

    # FIXME: Remove `content_type` option and respect `Content-Type` header
    def connection
      @connection ||= Faraday.new(url: ENV['TEST_TRACK_API_URL']) do |conn|
        conn.use Faraday::Request::Json
        conn.use Faraday::Response::Json, content_type: []
        conn.use ErrorMiddleware
        conn.use Faraday::Response::RaiseError
        # Number of seconds to wait for the connection to open.
        conn.options[:open_timeout] = (ENV['TEST_TRACK_OPEN_TIMEOUT'] || 2).to_i
        # Number of seconds to wait for one block to be read (via one read(2) call).
        conn.options[:timeout] = (ENV['TEST_TRACK_TIMEOUT'] || 4).to_i
      end
    end

    class ErrorMiddleware < Faraday::Middleware
      def call(env)
        super
      rescue *SERVER_ERRORS => e
        raise UnrecoverableConnectivityError, e
      end
    end
  end
end
