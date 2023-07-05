class Period < ActiveRecord::Base
  validates :name, presence: true
  validates :from, presence: true
  validates :to, presence: true

  has_many :credits, dependent: :destroy, autosave: true

  def get_stats(user_ids = [])
    total_num_of_days = (self.to - self.from).to_f
    current_num_of_days = (Date.today - self.from).to_f
    current_passed = current_num_of_days / total_num_of_days
    current_passed = 1 if current_passed > 1

    query = User
            .select('users.id AS user_id, users.username, users.email, users.superadmin, COALESCE(SUM(time_entries.decimal_time), 0) AS total_hours, credits.amount AS credits')
            .joins("LEFT JOIN time_entries ON time_entries.user_id = users.id AND (time_entries.created_at >= '#{self.from.to_time}' AND time_entries.created_at <= '#{self.to.to_time.end_of_day}')")
            .joins(:credits)
            .where('credits.period_id = ?', self.id)
            .group('users.username, users.email, users.superadmin, users.id, credits.amount')
            .order('users.username')

    query = query.where(users: { id: user_ids }) unless user_ids.empty?

    query.map do |record|
      record = record.attributes
      record['should_hours'] = current_passed * record['credits']
      record['balance'] = format('%.2f', record['total_hours'] - record['should_hours'])
      record['balance_percent'] = format('%.2f', (record['total_hours'] / record['should_hours']) * 100)
      record['should_hours'] = format('%.2f', record['should_hours'])
      record['total_hours'] = format('%.2f', record['total_hours'])
      record['credits'] = format('%.2f', record['credits'])
      record
    end
  end
end
