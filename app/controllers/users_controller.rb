class UsersController < ApplicationController
  before_action :superadmin?, except: %i[current_user_data sudo unsudo cas_logout]
  before_action :authenticate_user_json!, except: %i[cas_logout]

  # POST /sudo
  # Allows a superadmin or a timesheet admin to impersonate other users
  def sudo
    timesheet = Timesheet.where(id: params[:timesheet_id]).first

    render_bad_request and return if timesheet.nil?
    render_unauthorized and return unless user_can_manage_timesheet?(timesheet)

    session["#{current_user.id}_active_users"] = allowed_user_ids(timesheet)

    render json: { message: 'ok' }, status: :ok
  end

  # POST /unsudo
  # Stops impersonating other users
  def unsudo
    session["#{current_user.id}_active_users"] = []
    render json: { message: 'ok' }, status: :ok
  end

  # GET /current_user_data
  # Returns the current user's data
  def current_user_data
    render json: {
      username: current_user.email,
      user_id: current_user.id,
      is_superadmin: current_user.superadmin,
      sudo_users: active_user_ids,
    }, status: :ok
  end

  # GET /users
  # Returns a list of users with their roles in the given timesheet
  def index
    timesheet = Timesheet.find_by(id: params[:timesheet_id])
    render_bad_request and return if timesheet.nil?

    users = timesheet.users.select(:id, :email, :first_name, :last_name)
    render json: { users: users }, status: :ok
  end

  # GET /cas_logout
  # Logs out the current user and redirects to the CAS server logout page
  def cas_logout
    sign_out(current_user)
    session.destroy
    redirect_to "#{Timetracker::Application.config.rack_cas.server_url}/logout"
  end

  private

  def active_user_ids
    session["#{current_user.id}_active_users"] || []
  end

  def allowed_user_ids(timesheet)
    params[:users].map(&:to_i) & timesheet.users.pluck(:id)
  end
end
