class Period < ActiveRecord::Base
  validates :name, presence: true
  validates :from, presence: true
  validates :to, presence: true

  has_many :credits, dependent: :destroy, autosave: true

  def get_stats
    total_num_of_days = (self.to - self.from).to_f
    current_num_of_days = (Date.today - self.from).to_f
    current_passed = current_num_of_days / total_num_of_days

    query = "
      SELECT
        u.username,
        u.email,
        sum(t.decimal_time) as total_hours,
        c.amount as credits
      FROM
        users u
      JOIN
        credits c
        ON
        u.id=c.user_id
      LEFT JOIN
        time_entries t
        ON
        u.id=t.user_id
      WHERE
        t.created_at >= '#{self.from.to_time}'
        AND
        t.created_at <= '#{self.to.to_time.end_of_day}'
      GROUP BY
        username,
        email,
        amount
      ORDER BY
        username
    "

    records_array = ActiveRecord::Base.connection.execute(query)

    records_array.map do |record|
      record['should_hours'] = current_passed * record['credits']
      record['balance'] = record['total_hours'] - record['should_hours']
      record['balance_percent'] = (record['total_hours'] / record['should_hours']) * 100
      record
    end
  end
end
