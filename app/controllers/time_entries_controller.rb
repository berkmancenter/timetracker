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
    return render_unauthorized if active_users.nil?

    render_entries_csv and return if params[:csv]

    if params[:period].present?
      period = Period.find(params[:period])
      from_date = period.from
      to_date = period.to
    end

    month = params[:month]
    render json: TimeEntry.fetch_time_entries(active_users, {
      timesheet: @timesheet,
      month: month,
      alltime: (month == 'all'),
      from_date: from_date,
      to_date: to_date,
    }), status: :ok
  end

  # POST /time_entries
  # Creates or updates a time entry
  def edit
    time_entry_params = params.require(:time_entry).permit(:decimal_time, :entry_date)
    custom_fields = params[:time_entry][:fields] || {}

    time_entry = if params[:time_entry][:id].present?
      TimeEntry.find_by(id: params[:time_entry][:id])
    else
      TimeEntry.new do |entry|
        entry.entry_date = Time.current
        entry.decimal_time = 0
      end
    end

    return render_bad_request if time_entry.nil?

    return render_bad_request unless request.post? || request.patch?
    return render_unauthorized if time_entry.persisted? && !time_entry_owned_by_current_user?(time_entry)
    return render_bad_request if @timesheet.nil?
    return render_unauthorized unless user_can_use_timesheet?(@timesheet)
    return render_unauthorized if time_entry.persisted? && time_entry.timesheet != @timesheet

    if update_time_entry(time_entry, time_entry_params, custom_fields)
      render json: TimeEntry.single(time_entry.id), status: :ok
    else
      render_bad_request
    end
  end

  # DELETE /time_entries/:id/delete
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
    return render_unauthorized if active_users.nil?

    if params[:period].present?
      period = Period.find_by(id: params[:period])
      return render_bad_request unless period

      from_date = period.from
      to_date = period.to
    end

    entries = TimeEntry.fetch_time_entries(active_users, {
      timesheet: @timesheet,
      month: params[:month],
      group_by: params[:mode] == 'weeks' ? 'week' : 'day',
      from_date: from_date,
      to_date: to_date,
      alltime: (params[:month] == 'all')
    })

    render json: entries, status: :ok
  end

  # GET /time_entries/months
  # Returns a list of months with time entries
  def months
    return render_bad_request if @timesheet.nil?
    return render_unauthorized unless user_can_use_timesheet?(@timesheet)
    return render_unauthorized if active_users.nil?

    if params[:period].present?
      period = Period.find_by(id: params[:period])
      return render_bad_request unless period

      from_date = period.from
      to_date = period.to
    end

    render json: TimeEntry.entry_list_by_month(
      active_users,
      @timesheet,
      from_date: from_date,
      to_date: to_date
    )
  end

  # GET /time_entries/totals
  # Returns the total hours for the current month and the current timesheet
  def totals
    return render_bad_request if @timesheet.nil?
    return render_unauthorized unless user_can_use_timesheet?(@timesheet)
    return render_unauthorized if active_users.nil?

    render json: {
      total_hours_current_month: TimeEntry.total_hours_by_month(active_users, params[:month], @timesheet),
      total_hours_current_timesheet: TimeEntry.total_hours_by_timesheet(active_users, @timesheet)
    }, status: :ok
  end

  # GET /time_entries/auto_complete
  # Returns a list of values for the custom fields that match the term
  def auto_complete
    return render_bad_request if params[:field].nil? || params[:term].nil?

    field_obj = CustomField
                  .where(machine_name: params[:field], customizable_type: "Timesheet")
                  .joins("INNER JOIN timesheets ON timesheets.id = custom_fields.customizable_id")
                  .find_by("timesheets.uuid = ?", params[:timesheet_uuid])

    return render_bad_request unless field_obj.present?

    values = TimeEntry.where(user: current_user)
                      .joins(:custom_field_data_items)
                      .where(custom_field_data_items: { custom_field_id: field_obj.id })
                      .where('custom_field_data_items.value ILIKE ?', "%#{params[:term]}%")
                      .where.not('custom_field_data_items.value' => [nil, ''])
                      .group('custom_field_data_items.value')
                      .order(Arel.sql('COUNT(*) DESC'))
                      .limit(5)
                      .pluck('custom_field_data_items.value')

    render json: values
  end

  private

  def current_month
    @current_month ||= (params[:month].blank?) ? "#{Time.now.to_date.year}-#{Time.now.strftime("%m")}" : params[:month]
  end

  # Returns nil when the current user can't see the requested user, the
  # actions must render unauthorized then instead of fetching the entries.
  def active_users
    return @active_users if defined?(@active_users)

    @active_users = find_active_users
  end

  def find_active_users
    # Check for user_id in params first
    if params[:user].present?
      user = User.find_by(id: params[:user])
      # Verify current user has permission to view this user's data
      return [user] if user && (user_can_manage_timesheet?(@timesheet) || user.id == current_user.id)

      nil
    # Then check for session-stored active users
    elsif active_user_selection.present?
      selection = active_user_selection
      unless selection_timesheet_id(selection) == @timesheet.id && user_can_manage_timesheet?(@timesheet)
        session.delete(active_users_session_key)
        return [current_user]
      end

      return @timesheet.users.where(id: selection_user_ids(selection)).to_a
    # Default to current user
    else
      return [current_user]
    end
  end

  def active_user_selection
    selection = session[active_users_session_key]
    selection if selection.is_a?(Hash) && selection_user_ids(selection).any?
  end

  def active_users_session_key
    "#{current_user.id}_active_users"
  end

  def selection_timesheet_id(selection)
    (selection['timesheet_id'] || selection[:timesheet_id]).to_i
  end

  def selection_user_ids(selection)
    Array(selection['user_ids'] || selection[:user_ids]).map(&:to_i)
  end

  def render_entries_csv
    columns = %w[username entry_date decimal_time] + @timesheet.custom_fields.map(&:machine_name)
    entries = fetch_entries_for_csv

    render_csv(filebase: "time-entries-#{current_month}", model: TimeEntry, objects: format_entries_for_csv(entries, columns), columns: columns)
  end

  def fetch_entries_for_csv
    TimeEntry.fetch_time_entries(active_users, {
      timesheet: @timesheet,
      month: current_month,
      alltime: (current_month == 'all')
    })
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
      csv << param[:columns].map { |value| csv_safe_cell(value) }
      param[:objects].each do |record|
        csv << param[:columns].map { |col| csv_safe_cell(record[col]) }
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
    unless time_entry.persisted?
      time_entry.timesheet = @timesheet
      time_entry.user = current_user
    end

    if time_entry.save
      update_custom_fields(time_entry, custom_fields)
      true
    else
      false
    end
  end

  def update_custom_fields(time_entry, custom_fields)
    custom_fields.each do |machine_name, value|
      custom_field = CustomField.find_by(machine_name: machine_name, customizable: @timesheet)
      next unless custom_field

      field_data_item = CustomFieldDataItem.find_or_initialize_by(custom_field: custom_field, owner: time_entry)
      if value.blank?
        field_data_item.destroy if field_data_item.persisted?
      else
        field_data_item.update(value: value)
      end
    end
  end
end
