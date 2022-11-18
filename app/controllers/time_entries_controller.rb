class TimeEntriesController < ApplicationController
  before_action :is_admin, only: [:sudo, :unsudo, :choose_user, :clear_user, :view_other_timesheets]

  def index
    if params[:csv]
      columns = ['username', 'category', 'project', 'entry_date', 'decimal_time', 'description']
      objects = []
      @entries = []

      if month == 'all'
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
      @year_month = current_month
      @time_entry = TimeEntry.new(entry_date: Time.now, decimal_time: 0)
      render 'shared/_index', layout: true, locals: {entries: TimeEntry.my_entries_by_month(get_active_users, current_month, ((current_month == 'all') ? true : false )), new_time_entry: nil} and return
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
      @year_month = @time_entry.year_month
      new_time_entry = @time_entry.id
      @time_entry = TimeEntry.new(entry_date: Time.now, decimal_time: 0)
      params[:id] = nil
      render 'shared/_index', layout: ((request.xhr?) ? false : true), locals: {entries: TimeEntry.my_entries_by_month([@session_user],@year_month), new_time_entry: new_time_entry} and return
    else
      if request.xhr?
        message = @time_entry.errors.collect{|attribute,msg| "#{attribute} #{msg}"}.join('<br/>')
        render status: 500, layout: false, text: "We couldn't save that entry because: #{message}" and return
      end
    end
  end

  def clone
    begin
      te = TimeEntry.find(params[:id])
      teclone = te.attributes
      teclone.delete('id')
      teclone['entry_date'] = Time.now
      @time_entry = TimeEntry.new(teclone)
      params[:id] = nil
      render 'shared/_index', layout: ((request.xhr?) ? false : true), locals: {entries: TimeEntry.my_entries_by_month([@session_user],@time_entry.year_month), new_time_entry: nil} and return
    rescue Exception => exc
      render status: 500, text: "We couldn't clone that entry because: #{exc.message}" and return
    end
  end

  def delete
    begin
      te = TimeEntry.find(params[:id])

      return if te.user != @session_user

      @year_month = te.year_month
      te.destroy
      @time_entry = TimeEntry.new(entry_date: Time.now, decimal_time: 0)
      render 'shared/_index', layout: ((request.xhr?) ? false : true), locals: {entries: TimeEntry.my_entries_by_month(get_active_users, @year_month), new_time_entry: nil} and return
    rescue Exception => exc
      render status: 500, text: "We couldn't delete that entry because: #{exc.message}" and return
    end
  end

  def popular_categories
    render partial: 'shared/popular', collection: TimeEntry.my_popular_categories(@session_user), layout: ((request.xhr?) ? false : true), locals: { type: 'category' } and return
  end

  def popular_projects
    render partial: 'shared/popular', collection: TimeEntry.my_popular_projects(@session_user), layout: ((request.xhr?) ? false : true), locals: { type: 'project' } and return
  end

  def days
    year_month = (@year_month.blank?) ? params[:month] : @year_month
    render partial: 'shared/daily_summary', layout: ((request.xhr?) ? false : true), locals: { daily_summaries: TimeEntry.total_hours_by_month_day(get_active_users,year_month) } and return
  end

  def choose_user
    @users = User.where('id <> ?', @session_user.id).order(:username)
  end

  def months
    render partial: 'shared/months', layout: ((request.xhr?) ? false : true), locals: { months: TimeEntry.entry_list_by_month(get_active_users), current_month: current_month } and return
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
