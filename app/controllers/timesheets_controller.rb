class TimesheetsController < ApplicationController
  before_action :set_timesheet, only: %i[show send_invitations leave]

  def index
    render json: current_user.user_timesheets, status: :ok
  end

  def show
    generic_unauthorized_response and return unless @timesheet.is_admin?(current_user)

    render json: @timesheet, status: :ok
  end

  def upsert
    new_record = nil
    if timesheet_params[:id]
      timesheet = Timesheet.find(timesheet_params['id'])

      generic_unauthorized_response and return unless timesheet.is_admin?(current_user)

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
      unauth = true unless t.is_admin?(current_user)
    end
    generic_unauthorized_response and return if unauth

    if timesheets_ids&.any?
      Timesheet.where(id: timesheets_ids).destroy_all

      render json: { message: 'ok' }, status: :ok
    else
      render json: { message: 'No timesheets selected.' }, status: :bad_request
    end
  end

  def send_invitations
    generic_unauthorized_response and return unless @timesheet.is_admin?(current_user)

    email_regex = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/
    emails = params[:emails].scan(email_regex)

    invitations = []
    emails.each do |e|
      invitations << Invitation.new(email: e, sender: current_user, timesheet: @timesheet)
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

    ut = UsersTimesheet.new(user: current_user, timesheet: timesheet, role: 'user')

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

  private

  def set_timesheet
    @timesheet = Timesheet.find(params[:id])
  end

  def timesheet_params
    params.require(:timesheet).permit(:id, :name)
  end
end
