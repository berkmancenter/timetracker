class DropOldTimesheetTables < ActiveRecord::Migration[7.2]
  def change
    drop_table :timesheet_field_data_items
    drop_table :timesheet_fields
  end
end
