class User < ActiveRecord::Base
  has_many :time_entries, dependent: :destroy
  has_many :credits, dependent: :destroy
  has_many :users_workspaces, dependent: :destroy
  has_many :workspaces, through: :users_workspaces

  def self.with_time_entries
    self.select(:id, :username, :email)
        .joins(:time_entries)
        .group(:id, :username)
        .order(:username)
  end
end
