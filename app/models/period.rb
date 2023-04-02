class Period < ActiveRecord::Base
  validates :name, presence: true
  validates :from, presence: true
  validates :to, presence: true

  has_many :credits, dependent: :destroy, autosave: true

  def get_stats
    total_num_of_days = (self.to - self.from).to_f
    current_num_of_days = (Date.today - self.from).to_f
    current_passed = current_num_of_days / total_num_of_days
    current_passed = 1 if current_passed > 1

    User
      .select('users.username, users.email, COALESCE(SUM(time_entries.decimal_time), 0) AS total_hours, credits.amount AS credits')
      .joins("LEFT JOIN time_entries ON time_entries.user_id = users.id AND (time_entries.created_at >= '#{self.from.to_time}' AND time_entries.created_at <= '#{self.to.to_time.end_of_day}')")
      .joins(:credits)
      .where('credits.period_id = ?', self.id)
      .group('users.username, users.email, credits.amount')
      .order('users.username')
      .map do |record|
        record = record.attributes
        record['should_hours'] = current_passed * record['credits'].to_f
        record['balance'] = record['total_hours'].to_f - record['should_hours']
        record['balance_percent'] = (record['total_hours'].to_f / record['should_hours']) * 100
        record
      end
  end
end
