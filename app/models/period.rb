class Period < ActiveRecord::Base
  validates :name, presence: true
  validates :from, presence: true
  validates :to, presence: true
  validates :timesheet, presence: true

  has_many :credits, dependent: :destroy, autosave: true
  belongs_to :timesheet

  def get_stats
    total_num_of_days = (self.to - self.from).to_f
    current_num_of_days = (Date.today - self.from).to_f
    current_passed = current_num_of_days / total_num_of_days
    current_passed = 1 if current_passed > 1

    query = User
            .select('users.id AS user_id, users.username, users.email, COALESCE(SUM(time_entries.decimal_time), 0) AS total_hours, credits.amount AS credits, ARRAY_AGG(DISTINCT(users_timesheets.role)) AS roles')
            .joins("LEFT JOIN time_entries ON time_entries.user_id = users.id AND (time_entries.created_at >= '#{self.from.to_time}' AND time_entries.created_at <= '#{self.to.to_time.end_of_day}')")
            .joins(:credits)
            .joins(:users_timesheets)
            .where('time_entries.timesheet_id = ?', self.timesheet_id)
            .where('users_timesheets.timesheet_id = ?', self.timesheet_id)
            .where('credits.period_id = ?', self.id)
            .group('users.username, users.email, users.id, credits.amount')
            .order('users.username')

    query.map do |record|
      record = record.attributes
      record['admin'] = self.timesheet.admin?(User.find(record['user_id']))
      record['should_hours'] = current_passed * record['credits']
      record['balance'] = format('%.2f', record['total_hours'] - record['should_hours'])
      record['balance_percent'] = format('%.2f', (record['total_hours'] / record['should_hours']) * 100)
      record['should_hours'] = format('%.2f', record['should_hours'])
      record['total_hours'] = format('%.2f', record['total_hours'])
      record['credits'] = format('%.2f', record['credits'])
      record
    end
  end

  def self.user_periods(user)
    return Period.all if user.superadmin

    Period.joins(timesheet: :users_timesheets)
          .where(
            users_timesheets: {
              user_id: user.id,
              role: 'admin'
            }
          )
  end

  def self.timesheet_periods(timesheet)
    Period.where(timesheet_id: timesheet.id)
  end

  def self.user_periods_for_timesheet(user, timesheet)
    return Period.all if user.superadmin

    Period.joins(timesheet: :users_timesheets)
          .where(
            users_timesheets: {
              user_id: user.id,
              role: 'admin'
            },
            periods: {
              timesheet_id: timesheet.id
            }
          )
  end

  def self.admin_periods_for_timesheet(timesheet)
    return Period.all if timesheet.superadmin

    Period.joins(:users_timesheets)
          .where(
            users_timesheets: {
              timesheet_id: timesheet.id,
              role: 'admin'
            }
          )
  end
end
