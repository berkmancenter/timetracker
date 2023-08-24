class Workspace < ActiveRecord::Base
  has_many :time_entries
  has_many :users_workspaces
  has_many :users, through: :users_workspaces

  validates :name, presence: true
  validates :workspace, presence: true
end
