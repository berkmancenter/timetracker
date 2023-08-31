class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  before_action :authenticate_user!

  skip_before_action :verify_authenticity_token

  def ping
    render plain: 'pong'
  end

  protected

  def is_superadmin?
    redirect_to root_url unless current_user.superadmin
  end

  def generic_bad_request_response
    render json: { message: 'Bad request' }, status: :bad_request
  end

  def generic_unauthorized_response
    render json: { message: 'Unauthorized' }, status: :unauthorized
  end
end
