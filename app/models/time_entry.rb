class TimeEntry < ActiveRecord::Base
  belongs_to :user
  belongs_to :timesheet

  attribute :username

  validates :user, :entry_date, presence: true
  validates :timesheet, presence: true

  def self.my_popular_categories(user)
    self.get_popular('category', user)
  end

  def self.my_popular_projects(user)
    self.get_popular('project', user)
  end

  def self.my_entries_by_month(users, month = Time.now.year.to_s + '-' + Time.now.month.to_s, alltime = false, timesheet)
    user_ids = users.map(&:id)
    month = (month) ? month : Time.now.year.to_s + '-' + Time.now.month.to_s

    entries = TimeEntry
              .select('time_entries.*, users.username, users.id AS user_id')
              .joins(:user)
              .where(users: { id: user_ids })
              .where(timesheet: timesheet)
              .order(entry_date: :desc, id: :desc)

    if alltime
      entries
    else
      entries
        .where("#{year_month_entry_sql} = ?", month)
    end
  end

  def self.total_hours_by_month_day(users, month, timesheet)
    return [] if month.nil?

    user_ids = users.map(&:id)
    TimeEntry
      .select("users.username, entry_date, SUM(decimal_time) AS total_hours")
      .joins(:user)
      .where("#{year_month_entry_sql} = ?", month)
      .where(user_id: user_ids)
      .where(timesheet: timesheet)
      .group(:username, :entry_date)
      .order(entry_date: :desc)
  end

  def self.entry_list_by_month(users, timesheet)
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

  private

  def self.get_popular(type, user)
    where_clause = "#{type} IS NOT NULL AND LENGTH(#{type}) > 0"
    TimeEntry
      .select(type)
      .where(user: user)
      .where(where_clause)
      .group(type)
      .order(Arel.sql('COUNT(*) DESC'))
      .limit(20)
      .pluck(type)
  end

  def self.year_month_entry_sql
    "EXTRACT(year FROM entry_date) || '-' || LPAD(EXTRACT(month FROM entry_date)::text, 2, '0')"
  end

  def self.year_month_entry_sql_as
    "#{self.year_month_entry_sql} AS year_month_entry"
  end
end
