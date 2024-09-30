class TimeEntriesController < ApplicationController
  before_action :set_timesheet, only: %i[entries edit popular days months totals]
  before_action :authenticate_user_json!

  # GET /time_entries
  # Returns a list of time entries for the current user and current month
  # If the 'month' parameter is set to 'all', it will return all entries for the current user
  # If the 'csv' parameter is set, it will return the entries in CSV format
  def entries
    return render_bad_request if @timesheet.nil?
    return render_unauthorized unless user_can_use_timesheet?(@timesheet)
    render_entries_csv and return if params[:csv]

    month = params[:month]
    render json: TimeEntry.my_entries_by_month(active_users, month, month == 'all', @timesheet), status: :ok
  end

  # POST /time_entries
  # Creates or updates a time entry
  def edit
    time_entry_params = params.require(:time_entry).permit(:id, :decimal_time, :entry_date)
    custom_fields = params[:time_entry][:fields] || {}

    time_entry = TimeEntry.find_or_initialize_by(id: params[:time_entry][:id]) do |entry|
      entry.entry_date = Time.now
      entry.decimal_time = 0
    end

    return render_bad_request unless request.post? || request.patch?
    return render_unauthorized if time_entry.persisted? && !time_entry_owned_by_current_user?(time_entry)
    return render_bad_request if @timesheet.nil?
    return render_unauthorized unless user_can_use_timesheet?(@timesheet)

    if update_time_entry(time_entry, time_entry_params, custom_fields)
      render json: TimeEntry.single(time_entry.id), status: :ok
    else
      render_bad_request
    end
  end

  # GET /time_entries/:id/delete
  # Deletes a time entry
  def delete
    time_entry = TimeEntry.find(params[:id])

    return render_unauthorized unless time_entry_owned_by_current_user?(time_entry)

    time_entry.destroy

    render json: { message: 'ok' }, status: :ok
  end

  # GET /time_entries/popular
  # Returns a list of popular values for the custom fields
  def popular
    render json: TimeEntry.popular(current_user), status: :ok
  end

  # GET /time_entries/days
  # Returns a list of total hours for each day in the month
  # If the 'mode' parameter is set to 'weeks', it will return the total hours for each week
  def days
    return render_bad_request if @timesheet.nil?
    return render_unauthorized unless user_can_use_timesheet?(@timesheet)

    entries = if params[:mode] == 'weeks'
                TimeEntry.total_hours_by_month_week(active_users, params[:month], @timesheet)
              else
                TimeEntry.total_hours_by_month_day(active_users, params[:month], @timesheet)
              end

    render json: entries, status: :ok
  end

  # GET /time_entries/months
  # Returns a list of months with time entries
  def months
    return render_bad_request if @timesheet.nil?
    return render_unauthorized unless user_can_use_timesheet?(@timesheet)

    render json: TimeEntry.entry_list_by_month(active_users, @timesheet)
  end

  # GET /time_entries/totals
  # Returns the total hours for the current month and the current timesheet
  def totals
    return render_bad_request if @timesheet.nil?
    return render_unauthorized unless user_can_use_timesheet?(@timesheet)

    render json: {
      total_hours_current_month: TimeEntry.total_hours_by_month(active_users, params[:month], @timesheet),
      total_hours_current_timesheet: TimeEntry.total_hours_by_timesheet(active_users, @timesheet)
    }, status: :ok
  end

  # GET /time_entries/auto_complete
  # Returns a list of values for the custom fields that match the term
  def auto_complete
    return render_bad_request if params[:field].nil? || params[:term].nil?

    field_obj = TimesheetField.joins(:timesheet)
                              .find_by(machine_name: params[:field], timesheets: { uuid: params[:timesheet_uuid] })
    return render_bad_request unless field_obj.present?

    values = TimeEntry.where(user: current_user)
                      .joins(:timesheet_field_data_items)
                      .where(timesheet_field_data_items: { field_id: field_obj.id })
                      .where('timesheet_field_data_items.value ILIKE ?', "%#{params[:term]}%")
                      .where.not('timesheet_field_data_items.value' => [nil, ''])
                      .group('timesheet_field_data_items.value')
                      .order(Arel.sql('COUNT(*) DESC'))
                      .limit(5)
                      .pluck('timesheet_field_data_items.value')

    render json: values
  end

  private

  def current_month
    @current_month ||= (params[:month].blank?) ? "#{Time.now.to_date.year}-#{Time.now.strftime("%m")}" : params[:month]
  end

  def active_users
    unless session["#{current_user.id}_active_users"].blank?
      render_unauthorized and return unless user_can_use_timesheet?(@timesheet)
      session["#{current_user.id}_active_users"].map { |uid| User.where(id: uid).first }.compact
    else
      [current_user]
    end
  end

  def render_entries_csv
    columns = %w[username entry_date decimal_time] + @timesheet.timesheet_fields.map(&:machine_name)
    entries = fetch_entries_for_csv

    render_csv(filebase: "time-entries-#{current_month}", model: TimeEntry, objects: format_entries_for_csv(entries, columns), columns: columns)
  end

  def fetch_entries_for_csv
    TimeEntry.my_entries_by_month(active_users, current_month, current_month == 'all', @timesheet)
  end

  def format_entries_for_csv(entries, columns)
    entries.map do |entry|
      entry_attrs = entry.attributes
      entry_attrs['username'] = entry.user.email

      entry.fields.each do |key, value|
        entry_attrs[key] = value
      end

      entry_attrs
    end
  end

  def set_timesheet
    @timesheet = Timesheet.where(uuid: params.permit(:timesheet_uuid)[:timesheet_uuid]).first
  end

  def render_csv(param)
    param[:filebase] ||= param[:model].to_s.tableize
    param[:columns] ||= param[:model].columns.collect(&:name)

    csv_string = CSV.generate do |csv|
      csv << param[:columns]
      param[:objects].each do |record|
        csv << param[:columns].map { |col| record[col].to_s.chomp }
      end
    end

    send_data(
      csv_string,
      type: 'application/octet-stream',
      filename: "#{param[:filebase]}-#{Time.now.to_formatted_s(:number)}.csv"
    )
  end

  def time_entry_owned_by_current_user?(time_entry)
    time_entry.user == current_user || superadmin?
  end

  def update_time_entry(time_entry, time_entry_params, custom_fields)
    time_entry.assign_attributes(time_entry_params)
    time_entry.timesheet = @timesheet
    time_entry.user = current_user

    if time_entry.save
      update_custom_fields(time_entry, custom_fields)
      true
    else
      false
    end
  end

  def update_custom_fields(time_entry, custom_fields)
    custom_fields.each do |machine_name, value|
      timesheet_field = TimesheetField.find_by(machine_name: machine_name, timesheet: @timesheet)
      next unless timesheet_field

      field_data_item = TimesheetFieldDataItem.find_or_initialize_by(field_id: timesheet_field.id, time_entry_id: time_entry.id)
      if value.blank?
        field_data_item.destroy if field_data_item.persisted?
      else
        field_data_item.update(value: value)
      end
    end
  end
end
