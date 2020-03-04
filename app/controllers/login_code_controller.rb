class LoginCodeController < ApplicationController
  def index
    state = params[:state]
    code = params[:code]
    scope = params[:scope]
    redirect_uri = "#{ENV.fetch("ROOT_URL")}/login_code/"
    google_client_id = ENV.fetch("GOOGLE_CLIENT_ID")
    google_client_secret = ENV.fetch("GOOGLE_CLIENT_SECRET")

    body = "grant_type=authorization_code&" + \
               "code=#{code}&" + \
               "client_id=#{google_client_id}&" + \
               "client_secret=#{google_client_secret}&" + \
               "redirect_uri=#{redirect_uri}"

    response = HTTParty.post('https://oauth2.googleapis.com/token',
                        headers: {
                          'Content-Type' => 'application/x-www-form-urlencoded',
                        },
                        body: body)
    logged_info =
      "OAuth code: #{code}\n" + \
      "Redirect URI: #{redirect_uri}\n" + \
      "Response from https://oauth2.googleapis.com/token:\n\n#{response.body}"

    Rails.logger.info(logged_info)

    data = JSON.parse(response.body)

    if data['error'].present?
      raise ActiveRecord::RecordInvalid
    end

    # Verify Cognito JWT
    access_token = data['access_token']

    jwks_url = "https://www.googleapis.com/oauth2/v3/certs"
    jwks = HTTParty.get(jwks_url)['keys']
    keys = jwks.map{ |jwk| jwk['kid'] }

    key = JWT.decode(data["id_token"], nil, false)[1]['kid']
    
    keys = jwks.map{ |jwk| jwk['kid'] }

    unless keys.include?(key)
      raise ActiveRecord::RecordInvalid
    end

    @user_data = JWT.decode(data["id_token"], key, false)[0]
  end
end
