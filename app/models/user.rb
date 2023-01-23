class User < ActiveRecord::Base
  has_many :time_entries, dependent: :destroy
  has_many :credits, dependent: :destroy

  def self.with_time_entries
    self.find_by_sql('
      SELECT
        users.id,
        users.username,
        users.email
      FROM
        users,
        time_entries
      WHERE
        users.id = time_entries.user_id
      GROUP BY
        users.id,
        users.username
      ORDER BY
        users.username
    ')
  end
end
