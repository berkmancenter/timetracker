class TimeEntry < ActiveRecord::Base
  belongs_to :user
  belongs_to :timesheet
  has_many :custom_field_data_items, foreign_key: 'item_id', dependent: :destroy

  attribute :username

  validates :user, :entry_date, presence: true
  validates :timesheet, presence: true

  attr_accessor :fields

  def self.single(id)
    return nil if id.nil?

    entry = TimeEntry
            .select('time_entries.*, users.email, users.id AS user_id')
            .includes(custom_field_data_items: :custom_field)
            .joins(:user)
            .find_by(id: id)

    return nil unless entry

    # Extract associated data items and map them
    field_data = entry.custom_field_data_items.map do |field_data|
      [field_data.custom_field.machine_name, field_data.value]
    end.to_h

    # Merge field data into entry attributes
    entry.fields = field_data

    entry
  end

  def self.popular(user)
    return {} unless user.present?

    popular_fields = CustomField.where(popular: true)
    popular_values = {}

    popular_fields.each do |field|
      data_items = CustomFieldDataItem
        .joins(:time_entry)
        .where(custom_field_id: field.id, time_entries: { user_id: user.id })
        .where.not(value: [nil, ''])
        .group(:value)
        .order(Arel.sql('COUNT(*) DESC'))
        .limit(20)
        .count

      if data_items.keys.present?
        # Merge the values, concatenating arrays if the key already exists
        popular_values.merge!(field.machine_name => data_items.keys) do |key, old_val, new_val|
          old_val | new_val # Use the union operator to combine arrays without duplicates
        end
      end
    end

    popular_values
  end

  def self.fetch_time_entries(users = nil, options = {})
    # Initialize default options
    options = {
      timesheet: nil,
      month: nil,
      from_date: nil,
      to_date: nil,
      alltime: false,
      group_by: nil,
      aggregate: nil,
    }.merge(options)

    # Basic validation
    return options[:aggregate] == 'sum_hours' ? 0 : [] if options[:timesheet].nil?

    # Start building the query
    query = TimeEntry
            .joins(:user)
            .where(timesheet: options[:timesheet])

    # Set select fields based on aggregation
    if options[:aggregate] == 'sum_hours'
      query = query.select('SUM(decimal_time) AS total_hours')
    else
      query = query.select('time_entries.*, users.email, users.id AS user_id')
      query = query.order(entry_date: :desc, id: :desc)
      # Add includes if we're fetching individual entries
      query = query.includes(custom_field_data_items: :custom_field) if options[:group_by].nil?
    end

    # Filter by users if provided
    if users.present?
      user_ids = users.respond_to?(:map) ? users.map(&:id) : [users.id]
      query = query.where(users: { id: user_ids })
    end

    # Apply date filtering
    if options[:from_date].present? && options[:to_date].present?
      query = query.where(entry_date: options[:from_date]..options[:to_date])
    elsif options[:month].present? && !options[:alltime] && options[:month] != 'all'
      query = query.where("#{year_month_entry_sql} = ?", options[:month])
    elsif options[:month] == 'all'
      # Just so you know, this is a special case for the 'all' month
    elsif !options[:alltime] && options[:from_date].blank? && options[:to_date].blank?
      # Default to current month
      current_month = "#{Time.now.year}-#{Time.now.month.to_s.rjust(2, '0')}"
      query = query.where("#{year_month_entry_sql} = ?", current_month)
    end
    # Handle special case for 'all' with time limitation
    if options[:month] == 'all'
      if options[:group_by] == 'day'
        query = query.where("entry_date > CURRENT_DATE - INTERVAL '26 days'")
      elsif options[:group_by] == 'week'
        query = query.where("entry_date > CURRENT_DATE - INTERVAL '26 weeks'")
      end
    end

    # Handle aggregation requests specially
    if options[:aggregate] == 'sum_hours'
      result = query.to_a.first
      return result&.total_hours.to_f
    end

    # Process the results based on grouping
    case options[:group_by]
    when 'day'
      return process_daily_totals(query)
    when 'week'
      return process_weekly_totals(query, options[:month])
    else
      return process_individual_entries(query)
    end
  end

  # Helper methods to process different types of results
  def self.process_individual_entries(query)
    query.map do |entry|
      # Extract associated data items and map them
      field_data = entry.custom_field_data_items.map do |field_data|
        [field_data.custom_field.machine_name, field_data.value]
      end.to_h

      # Merge field data into entry attributes
      entry.fields = field_data

      entry
    end
  end

  def self.process_daily_totals(query)
    # Start with a fresh query that includes same conditions
    total_hours = TimeEntry
      .select('users.email, entry_date AS date, SUM(decimal_time) AS total_hours')
      .joins(:user)
      .merge(query.except(:select, :includes, :order))
      .group(:email, :entry_date)
      .order('date DESC')

    # Initialize a hash to store daily hours
    daily_hours = {}

    # Aggregate hours for each user for each day
    total_hours.each do |entry|
      formatted_date = entry.date.strftime('%Y-%m-%d')

      daily_hours[formatted_date] ||= {}
      daily_hours[formatted_date]['users'] ||= {}
      daily_hours[formatted_date]['users'][entry.email] ||= 0
      daily_hours[formatted_date]['users'][entry.email] += entry.total_hours.to_d
    end

    # Return nicer keyed structure
    final_daily_hours = []
    daily_hours.each do |date, daily_hours_record|
      daily_hours_record['users'].each do |email, daily_hours_user_record|
        final_daily_hours << {
          date: date,
          total_hours: daily_hours_user_record.to_d,
          email: email
        }
      end
    end

    final_daily_hours
  end

  def self.process_weekly_totals(query, month = nil)
    total_hours = TimeEntry
      .select("users.email, DATE_TRUNC('week', entry_date) AS date, SUM(decimal_time) AS total_hours")
      .joins(:user)
      .merge(query.except(:select, :includes, :order))
      .group(:email, :date)

    # Initialize a hash to store weekly hours
    weekly_hours = {}

    # Aggregate hours for each user for each week
    total_hours.each do |entry|
      week_start_object = entry.date.beginning_of_week(start_day = :sunday)
      week_start = week_start_object.strftime('%Y-%m-%d')

      if month.present? && month != 'all'
        week_start = "#{month}-01" if week_start_object.strftime('%Y-%m') != month
      end

      weekly_hours[week_start] ||= {}
      weekly_hours[week_start]['users'] ||= {}
      weekly_hours[week_start]['users'][entry.email] ||= 0
      weekly_hours[week_start]['users'][entry.email] += entry.total_hours.to_f
    end

    # Return nicer keyed structure
    final_weekly_hours = []
    weekly_hours.each do |date, weekly_hours_record|
      weekly_hours_record['users'].each do |email, weekly_hours_user_record|
        final_weekly_hours << {
          date: date,
          total_hours: weekly_hours_user_record,
          email: email
        }
      end
    end

    final_weekly_hours.reverse
  end

  def self.entry_list_by_month(users, timesheet, from_date: nil, to_date: nil)
    return [] unless users.present?
    return [] if timesheet.nil?

    user_ids = users.map(&:id)

    scope = TimeEntry
              .select(year_month_entry_sql_as)
              .where(user_id: user_ids)
              .where(timesheet: timesheet)

    scope = scope.where(entry_date: from_date..to_date) if from_date && to_date

    scope
      .group('year_month_entry')
      .order('year_month_entry desc')
      .map(&:year_month_entry)
  end

  def year_month
    "#{self.entry_date.to_date.year}-#{self.entry_date.strftime("%m")}"
  end

  def self.total_hours_by_month(users, month, timesheet)
    return 0 unless users.present?
    return 0 if month.nil?
    return 0 if timesheet.nil?

    fetch_time_entries(users, {
      timesheet: timesheet,
      month: month,
      aggregate: 'sum_hours'
    })
  end

  def self.total_hours_by_timesheet(users, timesheet)
    return 0 unless users.present?
    return 0 if timesheet.nil?

    fetch_time_entries(users, {
      timesheet: timesheet,
      alltime: true,
      aggregate: 'sum_hours'
    })
  end

  # Override the as_json method to include custom fields
  def as_json(options = {})
    super(options).merge('fields' => fields)
  end

  private

  def self.year_month_entry_sql
    Arel.sql("TO_CHAR(entry_date, 'YYYY-MM')")
  end

  def self.year_month_entry_sql_as
    "#{self.year_month_entry_sql} AS year_month_entry"
  end
end
