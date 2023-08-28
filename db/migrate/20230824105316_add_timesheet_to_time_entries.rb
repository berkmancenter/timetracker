class AddTimesheetToTimeEntries < ActiveRecord::Migration[7.0]
  def change
    default_timesheet = Timesheet.create(name: 'Default Timesheet')
    add_reference :time_entries, :timesheet, null: false, foreign_key: true, default: default_timesheet.id
    change_column_default :time_entries, :timesheet_id, from: default_timesheet.id
  end
end
