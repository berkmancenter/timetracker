class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token

  # GET /ping
  # Used by the front-end to check if the server is up and user is authenticated
  def ping
    render plain: 'pong'
  end

  def authenticate_user!(options = {})
    return super unless header_authentication?
    return if authenticate_user_from_headers

    render 'users/no_auth', status: :unauthorized
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
    if header_authentication?
      return if authenticate_user_from_headers

      render_unauthorized
      return false
    end
    return if current_user.present?

    render json: { message: 'Unauthorized' }, status: :unauthorized and return false
  end

  def authenticate_user_from_headers
    email = request.headers['X-Auth-Email'].to_s.strip
    name = request.headers['X-Auth-Name'].to_s.strip
    return false unless email.present? && name.present?

    user = User.from_auth_headers(email: email, name: name)
    request.env.fetch('warden').set_user(user, scope: :user, store: false)
    true
  end

  def header_authentication?
    Rails.application.config.devise_auth_type == 'headers'
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
