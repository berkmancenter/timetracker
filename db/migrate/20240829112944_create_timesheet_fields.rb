class CreateTimesheetFields < ActiveRecord::Migration[7.1]
  def change
    create_table :timesheet_fields do |t|
      t.string :input_type, limit: 50, null: false
      t.string :machine_name, limit: 500, null: false
      t.integer :timesheet_id
      t.integer :order, null: false, default: 1
      t.string :title, limit: 500, null: false
      t.text :description
      t.jsonb :metadata, null: false, default: -> { "'{}'::jsonb" }
      t.boolean :popular, null: false, default: false
      t.boolean :list, null: false, default: false
      t.boolean :required, null: false, default: false
      t.string :access_key, limit: 1
      t.timestamps
    end

    add_index :timesheet_fields, :timesheet_id, name: 'timesheet_fields_timesheet_id'
    add_index :timesheet_fields, :machine_name, name: 'timesheet_fields_machine_name'
  end
end
