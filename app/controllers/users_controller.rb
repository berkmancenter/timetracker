class UsersController < ApplicationController
  before_action :authenticate_user_json!, except: %i[cas_logout]

  # POST /sudo
  # Allows a superadmin or a timesheet admin to impersonate other users
  def sudo
    timesheet = Timesheet.where(id: params[:timesheet_id]).first

    render_bad_request and return if timesheet.nil?
    render_unauthorized and return unless user_can_manage_timesheet?(timesheet)

    session[active_users_session_key] = {
      'timesheet_id' => timesheet.id,
      'user_ids' => allowed_user_ids(timesheet)
    }

    render json: { message: 'ok' }, status: :ok
  end

  # POST /unsudo
  # Stops impersonating other users
  def unsudo
    session.delete(active_users_session_key)
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
    return unless authorize_user_for_timesheet!(timesheet)

    users = timesheet.users.select(:id, :email, :first_name, :last_name)
    render json: { users: users }, status: :ok
  end

  # DELETE /cas_logout
  # Logs out the current user and redirects to the CAS server logout page
  def cas_logout
    sign_out(current_user)
    session.destroy
    redirect_to "#{Timetracker::Application.config.rack_cas.server_url}/logout"
  end

  private

  def active_user_ids
    selection = session[active_users_session_key]
    return [] unless selection.is_a?(Hash)

    Array(selection['user_ids'] || selection[:user_ids]).map(&:to_i)
  end

  def allowed_user_ids(timesheet)
    Array(params[:users]).map(&:to_i) & timesheet.users.pluck(:id)
  end

  def active_users_session_key
    "#{current_user.id}_active_users"
  end
end
