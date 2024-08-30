require 'securerandom'

class Timesheet < ActiveRecord::Base
  has_many :time_entries, dependent: :destroy
  has_many :users_timesheets, dependent: :destroy
  has_many :users, through: :users_timesheets
  has_many :periods, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :timesheet_fields, dependent: :destroy

  accepts_nested_attributes_for :timesheet_fields, allow_destroy: true

  before_validation :set_uuid

  validates :name, presence: true
  validates :uuid, presence: true

  def admin?(user)
    return true if user.superadmin

    UsersTimesheet.where(
      timesheet: self,
      user: user,
      role: 'admin'
    ).any?
  end

  def user?(user)
    return true if user.superadmin

    UsersTimesheet.where(
      timesheet: self,
      user: user,
      role: %w[user admin]
    ).any?
  end

  def all_users
    users
      .select('
        users.id,
        users.email,
        users.username,
        users_timesheets.created_at AS joined,
        ARRAY_AGG(users_timesheets.role) AS roles
      ')
      .group('users.id, users_timesheets.created_at')
  end

  private

  def set_uuid
    self.uuid = SecureRandom.uuid if uuid.nil?
  end
end
