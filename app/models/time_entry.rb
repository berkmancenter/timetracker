class TimeEntry < ActiveRecord::Base
  belongs_to :user

  attribute :username

  def self.my_popular_categories(user)
    self.find_by_sql(['select category as item, count(category) as ccount from time_entries where user_id = ? and length(category) > 0 group by category order by ccount desc limit 20', user.id])
  end

  def self.my_popular_projects(user)
    self.find_by_sql(['select project as item, count(project) as pcount from time_entries where user_id = ? and length(project) > 0 group by project order by pcount desc limit 20', user.id])
  end

  def self.my_entries_by_month(users, month = Time.now.year.to_s + '-' + Time.now.month.to_s, alltime = false)
    users_sql = users.collect{|u| self.connection.quote(u.id)}.join(', ')
    month = (month) ? month : Time.now.year.to_s + '-' + Time.now.month.to_s
    if alltime
      self.find_by_sql(["select * from time_entries where user_id in (#{users_sql}) order by entry_date desc, id"])
    else
      self.find_by_sql(["select * from time_entries where extract(year from entry_date) || '-' || extract(month from entry_date) = ? and user_id in (#{users_sql}) order by entry_date desc, id", month])
    end
  end

  def self.total_hours_by_month_day(users,month = Time.now.year.to_s + '-' + Time.now.month.to_s)
    users_sql = users.collect{|u| self.connection.quote(u.id)}.join(', ')
    month = (month) ? month : Time.now.year.to_s + '-' + Time.now.month.to_s
    self.find_by_sql(["select users.username as username,entry_date,sum(decimal_time) as total_hours from time_entries,users where extract(year from entry_date) || '-' || extract(month from entry_date) = ? and user_id in(#{users_sql}) and time_entries.user_id = users.id group by username,entry_date order by entry_date",month])
  end

  def self.entry_list_by_month(users)
    users_sql = users.collect{|u| self.connection.quote(u.id)}.join(', ')
    self.find_by_sql("select extract(year from entry_date) || '-' || extract(month from entry_date) as month from time_entries where user_id in(#{users_sql}) group by month order by month")
  end

  def year_month
    "#{self.entry_date.to_date.year}-#{self.entry_date.to_date.month}"
  end
end
