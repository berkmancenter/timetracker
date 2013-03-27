class TimeEntryController < ApplicationController
  protect_from_forgery :except => [:auto_complete_for_time_entry_category, :auto_complete_for_time_entry_project]
  auto_complete_for :time_entry, :category
  auto_complete_for :time_entry, :project

  before_filter :is_admin, :only => [:sudo, :unsudo, :choose_user, :clear_user]

  def popular_categories
    render :partial => 'shared/popular', :collection => TimeEntry.my_popular_categories(@session_user), :layout => ((request.xhr?) ? false : true), :locals => {:type => 'category'} and return
  end

  def popular_projects
    render :partial => 'shared/popular', :collection => TimeEntry.my_popular_projects(@session_user), :layout => ((request.xhr?) ? false : true), :locals => {:type => 'project'} and return
  end

  def days
    year_month = (@year_month.blank?) ? params[:month] : @year_month
    render :partial => 'shared/daily_summary', :collection => TimeEntry.total_hours_by_month_day(get_active_users,year_month), :layout => ((request.xhr?) ? false : true) and return
  end

  def choose_user
    @users = User.find(:all, :conditions => ['id <> ?', @session_user.id], :order => 'username')
  end

  def clear_user
    u = User.find(params[:user_id])
    if u != @session_user
      u.destroy
      flash[:notice] = 'User removed.'
    else
      flash[:notice] = 'You can\'t remove yourself, you cheeky monkey!'
    end
    redirect_to :action => :index
  rescue
    flash[:notice] = 'There was a problem removing that user. Que malo!'
    redirect_to :action => :index
  end

  def months
    render :partial => 'shared/month', :collection => TimeEntry.entry_list_by_month(get_active_users), :layout => ((request.xhr?) ? false : true) and return
  end

  def sudo
    session["#{@session_user.id}_active_users"] = params[:active_users]
    if session["#{@session_user.id}_active_users"].blank?
      flash[:notice] = "You are now viewing only your own timesheets."
    else
      flash[:notice] = "You are now viewing the timesheet(s) of the user(s) you selected."
    end
    redirect_to :action => :index
  end

  def unsudo
    session["#{@session_user.id}_active_users"] = nil
    flash[:notice] = "You are browsing as yourself again."
    redirect_to :action => :index
  end

  def entry_form
    begin
      @time_entry = TimeEntry.find(params[:id])
      render :partial => 'shared/teedit', :layout => ((request.xhr?) ? false : true)
    rescue Exception => exc
      render :status => 500, :text => "We can't edit that entry because: #{exc.message}" and return
    end
  end

  def edit
    @time_entry = TimeEntry.find_by_id(params[:id]) || TimeEntry.new(:entry_date => Time.now, :decimal_time => 0)
    if request.post?
      @time_entry.attributes = params[:time_entry]
      @time_entry.category = @time_entry.category.downcase
      @time_entry.project = @time_entry.project.downcase
      @time_entry.user = @session_user
      if @time_entry.save
        @year_month = @time_entry.year_month
        new_time_entry = @time_entry.id
        @time_entry = TimeEntry.new(:entry_date => Time.now, :decimal_time => 0)
        params[:id] = nil
        render :partial => 'shared/index', :layout => ((request.xhr?) ? false : true), :locals => {:entries => TimeEntry.my_entries_by_month([@session_user],@year_month), :new_time_entry => new_time_entry} and return
      else
        if request.xhr?
          message = @time_entry.errors.collect{|attribute,msg| "#{attribute} #{msg}"}.join('<br/>')
          render :status => 500, :layout => false, :text => "We couldn't save that entry because: #{message}" and return
        end
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
      render :partial => 'shared/index', :layout => ((request.xhr?) ? false : true), :locals => {:entries => TimeEntry.my_entries_by_month([@session_user],@time_entry.year_month), :new_time_entry => nil} and return
    rescue Exception => exc
      render :status => 500, :text => "We couldn't clone that entry because: #{exc.message}" and return
    end
  end

  def delete
    begin
      te = TimeEntry.find(params[:id])
      @year_month = te.year_month
      te.destroy
      @time_entry = TimeEntry.new(:entry_date => Time.now, :decimal_time => 0)
      render :partial => 'shared/index', :layout => ((request.xhr?) ? false : true), :locals => {:entries => TimeEntry.my_entries_by_month(get_active_users,@year_month), :new_time_entry => nil} and return
    rescue Exception => exc
      render :status => 500, :text => "We couldn't delete that entry because: #{exc.message}" and return
    end
  end

  def view
  end

  def index
    month = (params[:month].blank?) ? nil : params[:month]
    if params[:csv]
      columns = ['username','category','project','entry_date','decimal_time','description']
      objects = []
      @entries = []
      if ! params[:all].blank?
        @entries = TimeEntry.my_entries_by_month(get_active_users,month,true)
      else 
        @entries = TimeEntry.my_entries_by_month(get_active_users,month)
      end
      @entries.each do |te|
        te[:username] = te.user.username
        objects << te
      end

      render_csv(:filebase => "time-entries-#{month}", :model => TimeEntry, :objects => objects, :columns => columns) and return
    else
      @year_month = params[:month]
      @time_entry = TimeEntry.new(:entry_date => Time.now, :decimal_time => 0)
      render :partial => 'shared/index', :layout => true, :locals => {:entries => TimeEntry.my_entries_by_month(get_active_users,month, ((params[:all].blank?) ? false : true )), :new_time_entry => nil} and return
    end
  end

end
