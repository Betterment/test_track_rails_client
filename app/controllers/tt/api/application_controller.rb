class Tt::Api::ApplicationController < ActionController::Base
  before_action :return_json

  private

  def return_json
    request.format = :json
  end
end
