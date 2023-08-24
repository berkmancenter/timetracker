class Workspace < ActiveRecord::Base
  has_many :time_entries

  validates :name, presence: true
  validates :workspace, presence: true
end
