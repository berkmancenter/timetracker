class UsersTimesheet < ApplicationRecord
  VALID_ROLES = %w[admin user].freeze

  belongs_to :user
  belongs_to :timesheet
  has_many :custom_fields, through: :timesheet

  validates :timesheet_id, uniqueness: { scope: :user_id }
  validates :role, inclusion: { in: VALID_ROLES }
end
