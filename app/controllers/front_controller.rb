class FrontController < ApplicationController
  before_action :authenticate_user!

  # GET /
  # Passes the request to the front-end
  def index
    render file: Rails.root.join('public', 'index_f.html').to_s, layout: false
  end

  # GET /ping
  # Used by the front-end to check if the server is up and user is authenticated
  def ping
    render plain: 'pong'
  end

  def authenticate_user!
    return super if current_user.present?

    redirect_to new_user_session_path
  end
end
