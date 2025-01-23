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

    def connection
      @connection ||= build_connection(
        url: ENV.fetch('TEST_TRACK_API_URL'),
        options: {
          open_timeout: ENV.fetch('TEST_TRACK_OPEN_TIMEOUT', '2').to_i,
          timeout: ENV.fetch('TEST_TRACK_TIMEOUT', '4').to_i
        }
      )
    end

    def build_connection(url:, options: {})
      Faraday.new(url) do |conn|
        conn.use Faraday::Request::Json
        conn.use Faraday::Response::Json, content_type: []
        conn.use ErrorMiddleware
        conn.use Faraday::Response::RaiseError
        conn.options.merge!(options)
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
