require 'faraday'

module TestTrack::Resource
  extend ActiveSupport::Concern

  include ActiveModel::API
  include ActiveModel::Attributes

  # FIXME: Raise UnrecoverableConnectivityError when we have a server error
  def self.connection
    @connection ||= Faraday.new(url: ENV['TEST_TRACK_API_URL']) do |conn|
      conn.request :json
      conn.response :json
      conn.response :raise_error
      conn.options[:open_timeout] = (ENV['TEST_TRACK_OPEN_TIMEOUT'] || 2).to_i # Number of seconds to wait for the connection to open.
      conn.options[:timeout] = (ENV['TEST_TRACK_TIMEOUT'] || 4).to_i # Number of seconds to wait for one block to be read (via one read(2) call).
    end
  end

  module Helpers
    private

    def faked?
      !TestTrack.enabled?
    end

    def connection
      TestTrack::Resource.connection
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
