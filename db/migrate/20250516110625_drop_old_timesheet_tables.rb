class DropOldTimesheetTables < ActiveRecord::Migration[7.2]
  def change
    drop_table :custom_field_data_items
    drop_table :custom_fields
  end
end
