class Api::CorsController < ActionController::Base
  include CorsSupport

  def allow
    head :no_content
  end
end
