class TimesheetsController < ApplicationController
  before_action :set_timesheet, only: %i[show send_invitations leave users delete_users change_users_role]
  before_action :authenticate_user_json!

  def index
    render json: current_user.user_timesheets, status: :ok
  end

  def index_where_admin
    render json: current_user.user_timesheets(only_admin: true), status: :ok
  end

  def show
    generic_unauthorized_response and return unless @timesheet.admin?(current_user) || superadmin?

    render json: @timesheet, status: :ok
  end

  def upsert
    new_record = nil
    if timesheet_params[:id]
      timesheet = Timesheet.find(timesheet_params['id'])

      generic_unauthorized_response and return unless timesheet.admin?(current_user) || superadmin?

      timesheet.assign_attributes(timesheet_params)
    else
      new_record = true
      timesheet = Timesheet.new(timesheet_params)
    end

    if timesheet.save
      UsersTimesheet.create(user: current_user, timesheet: timesheet, role: 'admin') if new_record
      render json: { timesheet: timesheet }, status: :ok
    else
      render json: { message: timesheet.errors.full_messages.join(', ') }, status: :bad_request
    end
  end

  def delete
    timesheets_ids = params[:timesheets]

    unauth = false
    Timesheet.where(id: timesheets_ids).each do |t|
      unauth = true unless t.admin?(current_user)
    end
    generic_unauthorized_response and return if unauth && !superadmin?

    if timesheets_ids&.any?
      Timesheet.where(id: timesheets_ids).destroy_all

      render json: { message: 'ok' }, status: :ok
    else
      render json: { message: 'No timesheets selected.' }, status: :bad_request
    end
  end

  def send_invitations
    generic_unauthorized_response and return unless @timesheet.admin?(current_user) || superadmin?

    email_regex = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/
    emails = params[:emails].scan(email_regex)

    role = params[:role]

    unless Invitation::VALID_ROLES.include?(role)
      render json: { message: 'Invalid role provided' }, status: :unprocessable_entity
      return
    end

    invitations = []
    emails.each do |e|
      invitations << Invitation.new(email: e, sender: current_user, timesheet: @timesheet, role: role)
    end

    Invitation.import!(invitations)

    invitations.each do |i|
      InvitationMailer.send_invitation(
        @timesheet, i
      ).deliver_later
    end

    render json: { message: 'ok' }, status: :ok
  end

  def join
    invitation = Invitation.where(code: params[:code]).first

    generic_bad_request_response and return if invitation.nil? || invitation.used

    timesheet = invitation.timesheet

    ut = UsersTimesheet.new(user: current_user, timesheet: timesheet, role: invitation.role)

    if ut.save
      invitation.used_by = current_user
      invitation.used = true
      invitation.save

      render json: { timesheet: timesheet }, status: :ok
    else
      render json: { message: ut.errors.full_messages.join(', ') }, status: :bad_request
    end
  end

  def leave
    UsersTimesheet
      .where(user: current_user, timesheet: @timesheet)
      .destroy_all

    render json: { message: 'ok' }, status: :ok
  end

  def users
    generic_bad_request_response and return if @timesheet.nil?
    generic_unauthorized_response and return unless @timesheet.admin?(current_user) || superadmin?

    render json: @timesheet.all_users, status: :ok
  end

  def delete_users
    generic_bad_request_response and return if @timesheet.nil?
    generic_unauthorized_response and return unless @timesheet.admin?(current_user) || superadmin?

    user_ids = params[:users]

    if user_ids&.any?
      UsersTimesheet.where(timesheet: @timesheet, user_id: user_ids).destroy_all

      render json: { message: 'ok' }, status: :ok
    else
      render json: { message: 'No users selected.' }, status: :bad_request
    end
  end

  def change_users_role
    generic_bad_request_response and return if @timesheet.nil?
    generic_unauthorized_response and return unless @timesheet.admin?(current_user) || superadmin?

    user_ids = params[:users]

    if user_ids&.any?
      UsersTimesheet.where(timesheet: @timesheet, user_id: user_ids).update_all(role: params[:role])

      render json: { message: 'ok' }, status: :ok
    else
      render json: { message: 'No users selected.' }, status: :bad_request
    end
  end

  private

  def set_timesheet
    @timesheet = Timesheet.where(id: params[:id]).first
  end

  def timesheet_params
    params.require(:timesheet).permit(:id, :name)
  end
end
