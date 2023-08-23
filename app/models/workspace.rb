class Workspace < ActiveRecord::Base
  validates :name, presence: true
end
