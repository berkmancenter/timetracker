class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token

  # GET /ping
  # Used by the front-end to check if the server is up and user is authenticated
  def ping
    render plain: 'pong'
  end

  protected

  def superadmin?
    current_user&.superadmin?
  end

  private

  def render_unauthorized(message = 'Unauthorized')
    render json: { message: message }, status: :unauthorized
  end

  def render_bad_request(message = 'Bad request')
    render json: { message: message }, status: :bad_request
  end

  def render_unprocessable_entity(message = 'Unprocessable entity')
    render json: { message: message }, status: :unprocessable_entity
  end

  def authenticate_user_json!
    return if current_user.present?

    render json: { message: 'Unauthorized' }, status: :unauthorized and return false
  end

  def user_can_manage_timesheet?(timesheet)
    timesheet.admin?(current_user) || superadmin?
  end

  def user_can_use_timesheet?(timesheet)
    timesheet.user?(current_user) || superadmin?
  end

  def authorize_user_for_timesheet!(timesheet)
    unless user_can_manage_timesheet?(timesheet)
      render_unauthorized
      return false
    end
    true
  end
end
