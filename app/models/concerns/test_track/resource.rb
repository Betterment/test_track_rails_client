require 'faraday'
require 'faraday/request/json'
require 'faraday/response/json'
require 'faraday/response/raise_error'

module TestTrack::Resource
  extend ActiveSupport::Concern

  include ActiveModel::API
  include ActiveModel::Attributes

  class << self
    attr_writer :connection

    # FIXME: Raise UnrecoverableConnectivityError when we have a server error
    # FIXME: Remove `content_type` option and respect `Content-Type` header
    def connection
      @connection ||= Faraday.new(url: ENV['TEST_TRACK_API_URL']) do |conn|
        conn.use Faraday::Request::Json
        conn.use Faraday::Response::Json, content_type: []
        conn.use Faraday::Response::RaiseError
        conn.options[:open_timeout] = (ENV['TEST_TRACK_OPEN_TIMEOUT'] || 2).to_i # Number of seconds to wait for the connection to open.
        conn.options[:timeout] = (ENV['TEST_TRACK_TIMEOUT'] || 4).to_i # Number of seconds to wait for one block to be read (via one read(2) call).
      end
    end
  end

  module Helpers
    private

    def fake_requests?
      !TestTrack.enabled?
    end

    def request(method:, path:, fake:, body: nil, headers: nil)
      # Ensure that fake responses are consistent with real responses
      return JSON.parse(JSON.generate(fake)) if fake_requests?

      response = TestTrack::Resource.connection.run_request(method, path, body, headers)
      response.body
    end
  end

  include Helpers

  module ClassMethods
    include Helpers
  end

  private

  def _assign_attribute(name, value)
    super
  rescue ActiveModel::UnknownAttributeError
    # Don't raise when we encounter an unknown attribute.
  end
end
