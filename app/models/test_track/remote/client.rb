require 'faraday'

module TestTrack::Remote::Client
  def faked?
    !TestTrack.enabled?
  end

  private

  def get(...) = TestTrack::Remote::Client.connection.get(...)

  def self.connection
    @connection ||= Faraday.new(url: ENV['TEST_TRACK_API_URL']) do |conn|
      conn.request :json
      conn.response :json
      conn.response :raise_error
      conn.options[:open_timeout] = (ENV['TEST_TRACK_OPEN_TIMEOUT'] || 2).to_i # Number of seconds to wait for the connection to open.
      conn.options[:timeout] = (ENV['TEST_TRACK_TIMEOUT'] || 4).to_i # Number of seconds to wait for one block to be read (via one read(2) call).
    end
  end
end
