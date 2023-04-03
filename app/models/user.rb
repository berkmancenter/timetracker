class User < ActiveRecord::Base
  has_many :time_entries, dependent: :destroy
  has_many :credits, dependent: :destroy

  def self.with_time_entries
    self.select(:id, :username, :email)
        .joins(:time_entries)
        .group(:id, :username)
        .order(:username)
  end
end
