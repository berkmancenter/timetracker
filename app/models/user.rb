class User < ActiveRecord::Base
  has_many :time_entries, dependent: :destroy
  has_many :credits, dependent: :destroy

  def self.with_time_entries
    self.find_by_sql('select users.id,users.username from users,time_entries where users.id = time_entries.user_id group by users.id,users.username order by users.username')
  end
end
