require 'securerandom'

class Timesheet < ActiveRecord::Base
  has_many :time_entries, dependent: :destroy
  has_many :users_timesheets, dependent: :destroy
  has_many :users, through: :users_timesheets
  has_many :periods, dependent: :destroy
  has_many :invitations, dependent: :destroy

  before_validation :set_uuid

  validates :name, presence: true
  validates :uuid, presence: true

  def is_admin?(user)
    return true if user.superadmin

    UsersTimesheet.where(
      timesheet: self,
      user: user,
      role: 'admin'
    ).any?
  end

  def is_user?(user)
    return true if user.superadmin

    UsersTimesheet.where(
      timesheet: self,
      user: user,
      role: %w[user admin]
    ).any?
  end

  private

  def set_uuid
    self.uuid = SecureRandom.uuid if uuid.nil?
  end
end
