class TimeEntry < ActiveRecord::Base
  belongs_to :user

  attribute :username

  validates :user, :entry_date, presence: true

  def self.my_popular_categories(user)
    self.get_popular('category', user)
  end

  def self.my_popular_projects(user)
    self.get_popular('project', user)
  end

  def self.my_entries_by_month(users, month = Time.now.year.to_s + '-' + Time.now.month.to_s, alltime = false)
    users_sql = users.collect{|u| self.connection.quote(u.id)}.join(', ')
    month = (month) ? month : Time.now.year.to_s + '-' + Time.now.month.to_s
    if alltime
      self.find_by_sql(["select time_entries.*, users.username from time_entries join users on time_entries.user_id = users.id where user_id in (#{users_sql}) order by entry_date desc, id"])
    else
      self.find_by_sql(["select time_entries.*, users.username from time_entries join users on time_entries.user_id = users.id where extract(year from entry_date) || '-' || lpad(extract(month from entry_date)::text, 2, '0') = ? and user_id in (#{users_sql}) order by entry_date desc, id", month])
    end
  end

  def self.total_hours_by_month_day(users, month)
    return [] if month.nil?

    month = self.connection.quote(month)
    users = users.collect { |u| self.connection.quote(u.id) }
                 .join(', ')
    self.connection.execute("select users.username as username, entry_date,sum(decimal_time) as total_hours from time_entries,users where extract(year from entry_date) || '-' || lpad(extract(month from entry_date)::text, 2, '0') = #{month} and user_id in (#{users}) and time_entries.user_id = users.id group by username,entry_date order by entry_date")
  end

  def self.entry_list_by_month(users)
    users_sql = users.collect{|u| self.connection.quote(u.id)}.join(', ')
    records = self.connection.execute("select extract(year from entry_date) || '-' || lpad(extract(month from entry_date)::text, 2, '0') as month from time_entries where user_id in(#{users_sql}) group by month order by month desc")
    records.map { |r| r['month'] }
  end

  def year_month
    "#{self.entry_date.to_date.year}-#{self.entry_date.strftime("%m")}"
  end

  private

  def self.get_popular(type, user)
    records = self.connection.execute(
      "select #{type} from time_entries where user_id = #{user.id} and length(#{type}) > 0 group by #{type} order by count(#{type}) desc limit 20"
    )
    records.map { |r| r[type] }
  end
end
