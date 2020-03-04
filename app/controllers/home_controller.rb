class HomeController < ApplicationController
  def index
    @REDIRECT_URI = "#{ENV.fetch('ROOT_URL')}/login_code/"
    @GOOGLE_CLIENT_ID = ENV.fetch('GOOGLE_CLIENT_ID')
  end
end
