class JwksController < ApplicationController
  def show
    expires_in 1.hour, public: true
    response.set_header "Access-Control-Allow-Origin", "*"
    render json: JwksKeyStore.current_jwks
  end
end
