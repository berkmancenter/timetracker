class TimeEntriesController < ApplicationController
  before_action :set_timesheet, only: %i[entries edit popular days months]

  def entries
    generic_bad_request_response and return if @timesheet.nil?
    generic_unauthorized_response and return unless @timesheet.is_user?(@session_user)
    render_entries_csv and return if params[:csv]

    month = params[:month]
    render json: TimeEntry.my_entries_by_month(get_active_users, month, month == 'all', @timesheet), status: :ok
  end

  def edit
    time_entry_params = params.require(:time_entry).permit(:id, :category, :project, :description, :decimal_time, :entry_date)
    time_entry = TimeEntry.find_by_id(params[:time_entry][:id]) || TimeEntry.new(entry_date: Time.now, decimal_time: 0)

    generic_bad_request_response and return unless request.post? || request.patch?
    generic_unauthorized_response and return if time_entry.id && time_entry.user != @session_user
    generic_bad_request_response and return if @timesheet.nil?

    time_entry.attributes = time_entry_params
    time_entry.timesheet = @timesheet
    time_entry.category = time_entry.category.downcase.strip
    time_entry.project = time_entry.project.downcase.strip
    time_entry.user = @session_user

    if time_entry.save
      render json: { entry: time_entry }, status: :ok
    else
      generic_bad_request_response
    end
  end

  def delete
    te = TimeEntry.find(params[:id])

    generic_unauthorized_response and return if te.user != @session_user

    te.destroy

    render json: { message: 'ok' }, status: :ok
  end

  def popular
    render json: {
      categories: TimeEntry.my_popular_categories(@session_user),
      projects: TimeEntry.my_popular_projects(@session_user)
    }, status: :ok
  end

  def days
    generic_bad_request_response and return if @timesheet.nil?
    generic_unauthorized_response and return unless @timesheet.is_user?(@session_user)

    render json: TimeEntry.total_hours_by_month_day(get_active_users, params[:month], @timesheet), status: :ok
  end

  def months
    generic_bad_request_response and return if @timesheet.nil?
    generic_unauthorized_response and return unless @timesheet.is_user?(@session_user)

    render json: TimeEntry.entry_list_by_month(get_active_users, @timesheet)
  end

  def auto_complete
    generic_bad_request_response and return if params[:field].nil? || params[:term].nil? || !['category', 'project'].include?(params[:field])

    render json: TimeEntry.where(user: @session_user).where("#{params[:field]} ilike ?", "%#{params[:term]}%").group(params[:field]).pluck(params[:field])
  end

  private

  def current_month
    @current_month ||= (params[:month].blank?) ? "#{Time.now.to_date.year}-#{Time.now.strftime("%m")}" : params[:month]
  end

  def get_active_users
    unless session["#{@session_user.id}_active_users"].blank?
      session["#{@session_user.id}_active_users"].map { |uid| User.where(id: uid).first }.compact
    else
      [@session_user]
    end
  end

  def render_entries_csv
    columns = ['username', 'category', 'project', 'entry_date', 'decimal_time', 'description']
    objects = []
    @entries = []

    if current_month == 'all'
      @entries = TimeEntry.my_entries_by_month(get_active_users, current_month, true, @timesheet)
    else
      @entries = TimeEntry.my_entries_by_month(get_active_users, current_month, false, @timesheet)
    end

    @entries.each do |te|
      te.username = te.user.username
      objects << te
    end

    render_csv(filebase: "time-entries-#{current_month}", model: TimeEntry, objects: objects, columns: columns) and return
  end

  def set_timesheet
    @timesheet = Timesheet.where(uuid: params.permit(:timesheet_uuid)[:timesheet_uuid]).first
  end
end
