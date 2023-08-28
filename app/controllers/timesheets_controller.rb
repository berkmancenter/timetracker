class TimesheetsController < ApplicationController
  before_action :set_timesheet, except: %i[index upsert delete]

  def index
    timesheets = Timesheet.user_timesheets(@session_user)
    timesheets = timesheets.select(:id, :uuid, :name)

    render json: timesheets, status: :ok
  end

  def show
    render json: @timesheet, status: :ok
  end

  def upsert
    new_record = nil
    if timesheet_params[:id]
      timesheet = Timesheet.find(timesheet_params['id'])
      timesheet.assign_attributes(timesheet_params)
    else
      new_record = true
      timesheet = Timesheet.new(timesheet_params)
    end

    if timesheet.save
      UsersTimesheet.create(user: @session_user, timesheet: timesheet, role: 'admin') if new_record
      render json: { timesheet: timesheet }, status: :ok
    else
      render json: { message: timesheet.errors.full_messages.join(', ') }, status: :bad_request
    end
  end

  def delete
    timesheets_ids = params[:timesheets]

    if timesheets_ids&.any?
      Timesheet.where(id: timesheets_ids).destroy_all

      render json: { message: 'ok' }, status: :ok
    else
      render json: { message: 'No timesheets selected.' }, status: :bad_request
    end
  end

  private

  def set_timesheet
    @timesheet = Timesheet.find(params[:id])
  end

  def timesheet_params
    params.require(:timesheet).permit(:id, :name)
  end
end
