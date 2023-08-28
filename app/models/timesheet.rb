require 'securerandom'

class Timesheet < ActiveRecord::Base
  has_many :time_entries
  has_many :users_timesheets
  has_many :users, through: :users_timesheets
  has_many :periods

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
    UsersTimesheet.where(
      timesheet: self,
      user: user,
      role: 'user'
    ).any?
  end

  def self.user_timesheets(user)
    return Timesheet.all if user.superadmin

    user.timesheets
  end

  private

  def set_uuid
    self.uuid = SecureRandom.uuid if uuid.nil?
  end
end
