require 'securerandom'

class Workspace < ActiveRecord::Base
  has_many :time_entries
  has_many :users_workspaces
  has_many :users, through: :users_workspaces

  before_validation :set_uuid

  validates :name, presence: true
  validates :uuid, presence: true

  def self.user_workspaces(user)
    return Workspace.all if user.superadmin

    user.workspaces
  end

  private

  def set_uuid
    self.uuid = SecureRandom.uuid if uuid.nil?
  end
end
