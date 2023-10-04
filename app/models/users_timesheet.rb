class UsersTimesheet < ActiveRecord::Base
  belongs_to :user
  belongs_to :timesheet

  validates :timesheet_id, uniqueness: { scope: :user_id }
end
