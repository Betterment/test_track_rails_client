require 'faraday'

module TestTrack
  class ServerErrorMiddleware < Faraday::Middleware
    def call(request_env)
      @app.call request_env
    rescue *SERVER_ERRORS => e
      raise UnrecoverableConnectivityError, e
    end
  end
end
