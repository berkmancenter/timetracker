class CreateCustomFieldDataItems < ActiveRecord::Migration[7.1]
  def change
    create_table :custom_field_data_items do |t|
      t.integer :field_id, null: false
      t.integer :time_entry_id, null: false
      t.text :value
      t.jsonb :value_json, null: false, default: -> { "'[]'::jsonb" }
      t.timestamps
    end

    add_index :custom_field_data_items, :field_id, name: 'custom_fields_data_item_field_id'
    add_index :custom_field_data_items, :time_entry_id, name: 'custom_field_data_time_entry_id'

    add_foreign_key :custom_field_data_items, :custom_fields, column: :field_id, primary_key: :id, on_update: :cascade, on_delete: :cascade
  end
end
