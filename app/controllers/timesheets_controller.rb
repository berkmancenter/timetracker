class TimesheetsController < ApplicationController
  before_action :set_timesheet, only: %i[show send_invitations leave users user delete_users change_users_role]
  before_action :authenticate_user_json!

  # GET /timesheets
  # Returns all timesheets for the current user
  def index
    timesheets = current_user.user_timesheets
    render json: timesheets.as_json(timesheet_json_params), status: :ok
  end

  # GET /timesheets/index_admin
  # Returns all timesheets for the current user where the user is an admin
  def index_admin
    timesheets = current_user.user_timesheets(only_admin: true)
    render json: timesheets.as_json(timesheet_json_params), status: :ok
  end

  # GET /timesheets/:id
  # Returns a specific timesheet
  def show
    return unless authorize_user_for_timesheet!(@timesheet)

    render json: @timesheet.as_json(timesheet_json_params), status: :ok
  end

  # POST /timesheets/upsert
  # Creates or updates a timesheet
  def upsert
    timesheet, new_record = set_or_create_timesheet

    return unless authorize_user_for_timesheet!(timesheet) if timesheet.persisted?

    # Check if there's at least one non-destroyed timesheet field
    has_valid_fields = timesheet_params[:custom_fields_attributes]&.any? do |field|
      field[:_destroy].nil? || field[:_destroy].to_s != 'true'
    end

    return render_bad_request('Timesheet must have at least one field') unless has_valid_fields

    if timesheet.save
      assign_current_user_as_admin(timesheet) if new_record
      render json: { timesheet: timesheet }, status: :ok
    else
      render_bad_request(timesheet.errors.full_messages.join(', '))
    end
  end

  # POST /timesheets/delete
  # Deletes timesheets
  def delete
    timesheets_ids = params[:timesheets]
    unauthorized = Timesheet.where(id: timesheets_ids).any? { |t| !user_can_manage_timesheet?(t) }

    return render_unauthorized if unauthorized || timesheets_ids.blank?

    Timesheet.where(id: timesheets_ids).destroy_all
    render json: { message: 'ok' }, status: :ok
  end

  # POST /timesheets/:id/send_invitations
  # Sends email invitations to users to join a timesheet
  def send_invitations
    return unless authorize_user_for_timesheet!(@timesheet)

    emails = extract_emails(params[:emails])
    role = params[:role]

    unless Invitation::VALID_ROLES.include?(role)
      return render_unprocessable_entity('Invalid role provided')
    end

    invitations = create_invitations(emails, role)
    deliver_invitations(invitations)
    render json: { message: 'ok' }, status: :ok
  end

  # GET /timesheets/join/:code
  # Joins a timesheet using an invitation code
  def join
    invitation = Invitation.find_by(code: params[:code])
    return render_bad_request('Invalid or already used invitation') unless valid_invitation?(invitation)

    timesheet = invitation.timesheet
    ut = UsersTimesheet.new(user: current_user, timesheet: timesheet, role: invitation.role)

    if ut.save
      mark_invitation_as_used(invitation)
      render json: { timesheet: timesheet }, status: :ok
    else
      render_bad_request(ut.errors.full_messages.join(', '))
    end
  end

  # GET /timesheets/:id/leave
  # Leaves a timesheet
  def leave
    UsersTimesheet.where(user: current_user, timesheet: @timesheet).destroy_all
    render json: { message: 'ok' }, status: :ok
  end

  # GET /timesheets/:id/users
  # Returns all users for a timesheet
  def users
    return unless authorize_user_for_timesheet!(@timesheet)

    render json: @timesheet.all_users, status: :ok
  end

  # GET /timesheets/:id/users/:id
  # Returns a specific user for a timesheet
  def user
    return unless authorize_user_for_timesheet!(@timesheet)

    user = User.find_by(id: params[:user_id])

    render json: user.as_json(only: %i[id email first_name last_name]), status: :ok
  end

  # POST /timesheets/:id/users
  # Adds users to a timesheet
  def add_users
    return unless authorize_user_for_timesheet!(@timesheet)

    emails = extract_emails(params[:emails])
    role = params[:role]

    unless Invitation::VALID_ROLES.include?(role)
      return render_unprocessable_entity('Invalid role provided')
    end

    invitations = create_invitations(emails, role)
    deliver_invitations(invitations)
    render json: { message: 'ok' }, status: :ok
  end

  # POST /timesheets/:id/delete_users
  # Deletes users from a timesheet
  def delete_users
    return unless authorize_user_for_timesheet!(@timesheet)

    user_ids = params[:users]
    if user_ids.blank?
      render_bad_request('No users selected.')
    else
      UsersTimesheet.where(timesheet: @timesheet, user_id: user_ids).destroy_all
      render json: { message: 'ok' }, status: :ok
    end
  end

  # POST /timesheets/:id/change_users_role
  # Changes the role of users in a timesheet
  def change_users_role
    return unless authorize_user_for_timesheet!(@timesheet)

    user_ids = params[:users]
    if user_ids.blank?
      render_bad_request('No users selected.')
    else
      UsersTimesheet.where(timesheet: @timesheet, user_id: user_ids).update_all(role: params[:role])
      render json: { message: 'ok' }, status: :ok
    end
  end

  private

  def set_timesheet
    @timesheet = Timesheet.includes(:custom_fields).find_by(id: params[:id])
  end

  def timesheet_params
    params.require(:timesheet).permit(:id, :name, custom_fields_attributes: %i[id title access_key input_type popular list order _destroy])
  end

  def timesheet_json_params
    {
      only: %i[id name uuid roles created_at],
      include: {
        custom_fields: {
          only: %i[id machine_name title order input_type popular list access_key access_value]
        }
      }
    }
  end

  def set_or_create_timesheet
    if timesheet_params[:id]
      timesheet = Timesheet.find(timesheet_params[:id])
      timesheet.assign_attributes(timesheet_params)
      [timesheet, false]
    else
      [Timesheet.new(timesheet_params), true]
    end
  end

  def assign_current_user_as_admin(timesheet)
    UsersTimesheet.create(user: current_user, timesheet: timesheet, role: 'admin')
  end

  def extract_emails(email_string)
    email_regex = /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b/
    email_string.scan(email_regex)
  end

  def create_invitations(emails, role)
    emails.map { |email| Invitation.new(email: email, sender: current_user, timesheet: @timesheet, role: role) }
  end

  def deliver_invitations(invitations)
    Invitation.import!(invitations)
    invitations.each { |invitation| InvitationMailer.send_invitation(@timesheet, invitation).deliver_later }
  end

  def valid_invitation?(invitation)
    invitation.present? && !invitation.used
  end

  def mark_invitation_as_used(invitation)
    invitation.update(used_by: current_user, used: true)
  end
end
