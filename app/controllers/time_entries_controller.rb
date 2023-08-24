class TimeEntriesController < ApplicationController
  before_action :is_admin, only: [:sudo, :unsudo, :choose_user, :clear_user, :view_other_timesheets]

  def entries
    render_entries_csv and return if params[:csv]

    month = params[:month]
    render json: TimeEntry.my_entries_by_month(get_active_users, month, month == 'all'), status: :ok
    end
  end

  def edit
    time_entry_params = params.require(:time_entry).permit(:id, :category, :project, :description, :decimal_time, :entry_date)
    @time_entry = TimeEntry.find_by_id(params[:time_entry][:id]) || TimeEntry.new(entry_date: Time.now, decimal_time: 0)

    return unless request.post? || request.patch?
    return if @time_entry.id && @time_entry.user != @session_user

    @time_entry.attributes = time_entry_params
    @time_entry.category = @time_entry.category.downcase.strip
    @time_entry.project = @time_entry.project.downcase.strip
    @time_entry.user = @session_user

    if @time_entry.save
      render json: { entry: @time_entry }, status: :ok
    else
      render json: { message: 'We couldn\'t save that entry' }, status: :bad_request
    end
  end

  def delete
    begin
      te = TimeEntry.find(params[:id])

      if te.user != @session_user
        render json: { message: 'Unauthorized' }, status: :unauthorized
        return
      end

      te.destroy

      render json: { message: 'ok' }, status: :ok
    rescue Exception => exc
      render json: { message: 'We couldn\'t delete that entry' }, status: :bad_request
    end
  end

  def popular
    render json: {
      categories: TimeEntry.my_popular_categories(@session_user),
      projects: TimeEntry.my_popular_projects(@session_user)
    }, status: :ok
  end

  def days
    render json: TimeEntry.total_hours_by_month_day(get_active_users, params[:month]), status: :ok
  end

  def choose_user
    @users = User.where('id <> ?', @session_user.id).order(:username)
  end

  def months
    render json: TimeEntry.entry_list_by_month(get_active_users)
  end

  def auto_complete
    if params[:field].nil? || params[:term].nil? || !['category', 'project'].include?(params[:field])
      head 500 and return
    end

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
      @entries = TimeEntry.my_entries_by_month(get_active_users, current_month, true)
    else
      @entries = TimeEntry.my_entries_by_month(get_active_users, current_month)
    end

    @entries.each do |te|
      te.username = te.user.username
      objects << te
    end

    render_csv(filebase: "time-entries-#{current_month}", model: TimeEntry, objects: objects, columns: columns) and return
  end
end
