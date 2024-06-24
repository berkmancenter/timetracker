class FrontController < ApplicationController
  before_action :authenticate_user!

  def index
    render file: 'public/index_f.html', layout: false
  end

  def authenticate_user!
    redirect_to new_user_session_path and return if current_user.nil?

    super
  end
end
