class AddUniqueConstraintToUsersTimesheets < ActiveRecord::Migration[7.0]
  def up
    add_index :users_timesheets, %w[user_id timesheet_id], unique: true, name: 'unique_user_timesheet'
  end

  def down
    remove_index :users_timesheets, name: 'unique_user_timesheet'
  end
end
