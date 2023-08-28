class User < ActiveRecord::Base
  has_many :time_entries, dependent: :destroy
  has_many :credits, dependent: :destroy
  has_many :users_timesheets, dependent: :destroy
  has_many :timesheets, through: :users_timesheets

  def self.with_time_entries
    self.select(:id, :username, :email)
        .joins(:time_entries)
        .group(:id, :username)
        .order(:username)
  end
end
