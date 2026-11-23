class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, if: :header_authentication?
  after_action :set_csrf_cookie, unless: :header_authentication?

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

  CSV_FORMULA_PREFIX = /\A[[:space:]]*(?:[=+\-@]|[\t\r])/.freeze
  CSV_NUMERIC_LITERAL = /\A[+\-]?(?:\d+(?:\.\d*)?|\.\d+)(?:e[+\-]?\d+)?\z/i.freeze

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
    return false unless trusted_auth_proxy?

    user = User.from_auth_headers(email: email, name: name)
    request.env.fetch('warden').set_user(user, scope: :user, store: false)
    true
  end

  def header_authentication?
    Rails.application.config.devise_auth_type == 'headers'
  end

  # The auth headers are only trusted when the request comes straight from the
  # auth proxy. REMOTE_ADDR is the direct peer, it can't be faked with headers.
  def trusted_auth_proxy?
    remote_addr = IPAddr.new(request.remote_addr.to_s).native
    trusted = Rails.application.config.auth_headers_trusted_proxies.any? { |proxy| proxy.include?(remote_addr) }
    logger.warn("Ignoring auth headers from untrusted address #{request.remote_addr}") unless trusted
    trusted
  rescue IPAddr::Error
    false
  end

  def set_csrf_cookie
    cookies['CSRF-TOKEN'] = {
      value: form_authenticity_token,
      path: '/',
      same_site: :lax,
      secure: request.ssl?
    }
  end

  def csv_safe_cell(value)
    cell = value.to_s.chomp
    return cell if cell.match?(CSV_NUMERIC_LITERAL)

    cell.match?(CSV_FORMULA_PREFIX) ? "'#{cell}" : cell
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
