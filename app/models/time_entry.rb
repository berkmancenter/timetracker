class TimeEntry < ApplicationRecord
  belongs_to :user
  belongs_to :timesheet
  has_many :custom_field_data_items, as: :owner, dependent: :destroy

  attribute :username

  validates :user, :entry_date, presence: true
  validates :timesheet, presence: true
  validates :decimal_time, numericality: { greater_than_or_equal_to: 0, less_than: 100 }

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

  def self.popular(user, timesheet = nil)
    return {} if user.blank? || timesheet.blank?

    ranked_values = CustomFieldDataItem
      .joins(:custom_field)
      .joins('INNER JOIN time_entries ON time_entries.id = custom_field_data_items.owner_id')
      .where(
        owner_type: 'TimeEntry',
        custom_fields: { customizable_type: 'Timesheet', customizable_id: timesheet.id, popular: true },
        time_entries: { user_id: user.id, timesheet_id: timesheet.id }
      )
      .where.not(value: [nil, ''])
      .group('custom_fields.machine_name', 'custom_field_data_items.value')
      .select(
        'custom_fields.machine_name AS field_name',
        'custom_field_data_items.value AS field_value',
        'ROW_NUMBER() OVER (PARTITION BY custom_fields.machine_name ORDER BY COUNT(*) DESC, custom_field_data_items.value ASC) AS rank'
      )

    rows = CustomFieldDataItem
      .from("(#{ranked_values.to_sql}) AS ranked_popular_values")
      .where('rank <= 20')
      .order('field_name ASC, rank ASC')
      .pluck(Arel.sql('field_name'), Arel.sql('field_value'))

    rows.each_with_object({}) do |(field_name, value), popular_values|
      (popular_values[field_name] ||= []) << value
    end
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

    # nil means no user filter; an empty selection must return no entries.
    unless users.nil?
      user_ids = users.respond_to?(:map) ? users.map(&:id) : [users.id]
      query = query.where(users: { id: user_ids })
    end

    # Apply date filtering
    if options[:from_date].present? && options[:to_date].present?
      query = query.where(entry_date: options[:from_date]..options[:to_date])
    elsif options[:month].present? && !options[:alltime] && options[:month] != 'all'
      date_range = month_date_range(options[:month])
      query = date_range ? query.where(entry_date: date_range) : query.none
    elsif options[:month] == 'all'
      # Just so you know, this is a special case for the 'all' month
    elsif !options[:alltime] && options[:from_date].blank? && options[:to_date].blank?
      # Default to current month
      current_month_start = Date.current.beginning_of_month
      query = query.where(entry_date: current_month_start..current_month_start.end_of_month)
    end
    # Handle special case for 'all' with time limitation
    if options[:month] == 'all'
      if options[:group_by] == 'day'
        query = query.where('entry_date > ?', Date.current - 26.days)
      elsif options[:group_by] == 'week'
        query = query.where('entry_date > ?', Date.current - 26.weeks)
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
      daily_hours[formatted_date]['users'][entry.email] += entry.total_hours.to_f
    end

    # Return nicer keyed structure
    final_daily_hours = []
    daily_hours.each do |date, daily_hours_record|
      daily_hours_record['users'].each do |email, daily_hours_user_record|
        final_daily_hours << {
          date: date,
          total_hours: daily_hours_user_record.to_f,
          email: email
        }
      end
    end

    final_daily_hours
  end

  def self.process_weekly_totals(query, month = nil)
    # Truncate directly to Sunday-start weeks in PostgreSQL (DOW: Sunday = 0 .. Saturday = 6)
    week_start_sql = '(entry_date - EXTRACT(DOW FROM entry_date)::integer)'
    total_hours = TimeEntry
      .select("users.email, #{week_start_sql} AS date, SUM(decimal_time) AS total_hours")
      .joins(:user)
      .merge(query.except(:select, :includes, :order))
      .group("users.email, #{week_start_sql}")
      .order(Arel.sql('date DESC, users.email ASC'))

    weekly_hours = {}

    total_hours.each do |entry|
      week_start_object = entry.date.to_date
      week_start = week_start_object.strftime('%Y-%m-%d')

      if month.present? && month != 'all' && week_start_object.strftime('%Y-%m') != month
        week_start = "#{month}-01"
      end

      weekly_hours[week_start] ||= {}
      weekly_hours[week_start][entry.email] ||= 0.0
      weekly_hours[week_start][entry.email] += entry.total_hours.to_f
    end

    weekly_hours.flat_map do |date, users_hours|
      users_hours.map do |email, hours|
        {
          date: date,
          total_hours: hours,
          email: email
        }
      end
    end
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

  def self.month_date_range(month_str)
    match = /\A(\d{4})-(\d{2})\z/.match(month_str.to_s)
    return nil unless match

    start_date = Date.new(match[1].to_i, match[2].to_i, 1)
    start_date..start_date.end_of_month
  rescue Date::Error
    nil
  end

  def self.year_month_entry_sql
    Arel.sql("TO_CHAR(entry_date, 'YYYY-MM')")
  end

  def self.year_month_entry_sql_as
    "#{self.year_month_entry_sql} AS year_month_entry"
  end
end
