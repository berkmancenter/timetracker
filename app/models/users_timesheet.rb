class UsersTimesheet < ActiveRecord::Base
  belongs_to :user
  belongs_to :timesheet
  has_many :custom_fields, through: :timesheet

  validates :timesheet_id, uniqueness: { scope: :user_id }
end
