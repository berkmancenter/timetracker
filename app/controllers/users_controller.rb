class UsersController < ApplicationController
  before_action :superadmin?, except: %i[current_user_data sudo unsudo cas_logout]
  before_action :authenticate_user_json!, except: %i[cas_logout]

  def sudo
    timesheet = Timesheet.where(id: params[:timesheet_id]).first

    generic_bad_request_response and return if timesheet.nil?
    generic_unauthorized_response and return unless timesheet.admin?(current_user)

    allowed_user_ids = params[:users].map(&:to_i) & timesheet.users.pluck(:id)

    session["#{current_user.id}_active_users"] = allowed_user_ids

    render json: { message: 'ok' }, status: :ok
  end

  def unsudo
    session["#{current_user.id}_active_users"] = []

    render json: { message: 'ok' }, status: :ok
  end

  def current_user_data
    render json: {
      username: current_user.email,
      user_id: current_user.id,
      is_superadmin: current_user.superadmin,
      sudo_users: get_sudo_users_emails
    }, status: :ok
  end

  def cas_logout
    sign_out(current_user)
    session.destroy
    redirect_to "#{Timetracker::Application.config.rack_cas.server_url}/logout"
  end

  private

  def get_sudo_users
    unless session["#{current_user.id}_active_users"].blank?
      session["#{current_user.id}_active_users"].map { |uid| User.where(id: uid).first }.compact
    else
      []
    end
  end

  def get_sudo_users_emails
    get_sudo_users.map { |u| User.where(id: u).first&.email }.compact
  end
end
