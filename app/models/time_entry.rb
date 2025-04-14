class TimeEntry < ActiveRecord::Base
  belongs_to :user
  belongs_to :timesheet
  has_many :timesheet_field_data_items, foreign_key: 'time_entry_id', dependent: :destroy

  attribute :username

  validates :user, :entry_date, presence: true
  validates :timesheet, presence: true

  attr_accessor :fields

  def self.single(id)
    return nil if id.nil?

    entry = TimeEntry
            .select('time_entries.*, users.email, users.id AS user_id')
            .includes(timesheet_field_data_items: :timesheet_field)
            .joins(:user)
            .find_by(id: id)

    return nil unless entry

    # Extract associated data items and map them
    field_data = entry.timesheet_field_data_items.map do |field_data|
      [field_data.timesheet_field.machine_name, field_data.value]
    end.to_h

    # Merge field data into entry attributes
    entry.fields = field_data

    entry
  end

  def self.popular(user)
    return {} unless user.present?

    popular_fields = TimesheetField.where(popular: true)
    popular_values = {}

    popular_fields.each do |field|
      data_items = TimesheetFieldDataItem
        .joins(:time_entry)
        .where(field_id: field.id, time_entries: { user_id: user.id })
        .where.not(value: nil)
        .where.not(value: '')
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

  def self.my_entries_by_month(users, month = "#{Time.now.year}-#{Time.now.month}", alltime = false, timesheet)
    return [] unless users.present?
    return [] if month.nil?
    return [] if timesheet.nil?

    user_ids = users.map(&:id)
    month ||= "#{Time.now.year}-#{Time.now.month}"

    entries = TimeEntry
              .select('time_entries.*, users.email, users.id AS user_id')
              .includes(timesheet_field_data_items: :timesheet_field)
              .joins(:user)
              .where(users: { id: user_ids })
              .where(timesheet: timesheet)
              .order(entry_date: :desc, id: :desc)

    entries = entries.where("#{year_month_entry_sql} = ?", month) unless alltime

    entries.map do |entry|
      # Extract associated data items and map them
      field_data = entry.timesheet_field_data_items.map do |field_data|
        [field_data.timesheet_field.machine_name, field_data.value]
      end.to_h

      # Merge field data into entry attributes
      entry.fields = field_data

      entry
    end
  end

  def self.total_hours_by_month_day(users, month, timesheet)
    return [] unless users.present?
    return [] if month.nil?
    return [] if timesheet.nil?

    user_ids = users.map(&:id)
    total_hours = TimeEntry
      .select("users.email, entry_date AS date, SUM(decimal_time) AS total_hours")
      .joins(:user)
      .where(user_id: user_ids)
      .where(timesheet: timesheet)

    if (month == 'all')
      total_hours = total_hours
        .where("entry_date > CURRENT_DATE - INTERVAL '26 days'")
    else
      total_hours = total_hours.where("#{year_month_entry_sql} = ?", month)
    end

    total_hours = total_hours
      .group(:email, :entry_date)
      .order(date: :desc)

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

  def self.total_hours_by_month_week(users, month, timesheet)
    return [] unless users.present?
    return [] if month.nil?
    return [] if timesheet.nil?

    user_ids = users.map(&:id)
    total_hours = TimeEntry
      .select("users.email, DATE_TRUNC('week', entry_date) AS date, SUM(decimal_time) AS total_hours")
      .joins(:user)
      .where(user_id: user_ids)
      .where(timesheet: timesheet)

    if (month == 'all')
      total_hours = total_hours
        .where("entry_date > CURRENT_DATE - INTERVAL '26 weeks'")
    else
      total_hours = total_hours.where("#{year_month_entry_sql} = ?", month)
    end

    total_hours = total_hours
      .group(:email, :date)

    # Initialize a hash to store weekly hours
    weekly_hours = {}

    # Aggregate hours for each user for each week
    total_hours.each do |entry|
      week_start_object = entry.date.beginning_of_week(start_day = :sunday)
      week_start = week_start_object.strftime('%Y-%m-%d')

      if month != 'all'
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

  def self.entry_list_by_month(users, timesheet)
    return [] unless users.present?
    return [] if timesheet.nil?

    user_ids = users.map(&:id)
    TimeEntry
      .select(year_month_entry_sql_as)
      .where(user_id: user_ids)
      .where(timesheet: timesheet)
      .group('year_month_entry')
      .order('year_month_entry desc')
      .map(&:year_month_entry)
  end

  def year_month
    "#{self.entry_date.to_date.year}-#{self.entry_date.strftime("%m")}"
  end

  def self.total_hours_by_month(users, month, timesheet)
    return [] unless users.present?
    return [] if month.nil?
    return [] if timesheet.nil?

    user_ids = users.map(&:id)
    TimeEntry
      .select('SUM(decimal_time) AS total_hours')
      .joins(:user)
      .where("#{year_month_entry_sql} = ?", month)
      .where(user_id: user_ids)
      .where(timesheet: timesheet)
      .to_a
      .map(&:total_hours)
      .first || 0
  end

  def self.total_hours_by_timesheet(users, timesheet)
    return [] unless users.present?
    return [] if timesheet.nil?

    user_ids = users.map(&:id)
    TimeEntry
      .select('SUM(decimal_time) AS total_hours')
      .joins(:user)
      .where(user_id: user_ids)
      .where(timesheet: timesheet)
      .to_a
      .map(&:total_hours)
      .first || 0
  end

  # Override the as_json method to include custom fields
  def as_json(options = {})
    super(options).merge('fields' => fields)
  end

  private

  def self.year_month_entry_sql
    "EXTRACT(year FROM entry_date) || '-' || LPAD(EXTRACT(month FROM entry_date)::text, 2, '0')"
  end

  def self.year_month_entry_sql_as
    "#{self.year_month_entry_sql} AS year_month_entry"
  end
end
