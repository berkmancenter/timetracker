class FrontController < ApplicationController
  before_action :authenticate_user!

  # GET /
  # Passes the request to the front-end
  def index
    render file: 'public/index_f.html', layout: false
  end

  def authenticate_user!
    return super if current_user.present?

    redirect_to new_user_session_path
  end
end
