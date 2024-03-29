class CreateUsersTimesheets < ActiveRecord::Migration[7.0]
  def change
    create_table :users_timesheets do |t|
      t.references :user, foreign_key: true
      t.references :timesheet, foreign_key: true
      t.string :role

      t.timestamps
    end

    User.all.each do |u|
      UsersTimesheet.create(user: u, timesheet_id: Timesheet.all.first, role: 'user')
    end
  end
end
