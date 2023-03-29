class TimeEntriesController < ApplicationController
  before_action :is_admin, only: [:sudo, :unsudo, :choose_user, :clear_user, :view_other_timesheets]

  def entries
    if params[:csv]
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
    else
      month = params[:month]
      render json: {
        entries: TimeEntry.my_entries_by_month(get_active_users, month, month == 'all')
      }, status: :ok
    end
  end

  def edit
    time_entry_params = params.require(:time_entry).permit(:id, :category, :project, :description, :decimal_time, :entry_date)
    @time_entry = TimeEntry.find_by_id(params[:time_entry][:id]) || TimeEntry.new(entry_date: Time.now, decimal_time: 0)

    return unless request.post? || request.patch?
    return if @time_entry.id && @time_entry.user != @session_user

    @time_entry.attributes = time_entry_params
    @time_entry.category = @time_entry.category.downcase
    @time_entry.project = @time_entry.project.downcase
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
    render json: { daily_totals: TimeEntry.total_hours_by_month_day(get_active_users, params[:month]) }, status: :ok
  end

  def choose_user
    @users = User.where('id <> ?', @session_user.id).order(:username)
  end

  def months
    render json: TimeEntry.entry_list_by_month(get_active_users)
  end

  def entry_form
    begin
      @time_entry = TimeEntry.find(params[:id])
      render 'shared/_teedit', layout: ((request.xhr?) ? false : true)
    rescue Exception => exc
      render status: 500, text: "We can't edit that entry because: #{exc.message}" and return
    end
  end

  def auto_complete
    if params[:field].nil? || params[:term].nil? || !['category', 'project'].include?(params[:field])
      head 500 and return
    end

    render json: TimeEntry.where("#{params[:field]} ilike ?", "%#{params[:term]}%").group(params[:field]).pluck(params[:field])
  end

  private

  def current_month
    @current_month ||= (params[:month].blank?) ? "#{Time.now.to_date.year}-#{Time.now.strftime("%m")}" : params[:month]
  end
end
