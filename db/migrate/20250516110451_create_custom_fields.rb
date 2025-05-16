class CreateCustomFields < ActiveRecord::Migration[7.2]
  def change
    create_table :custom_fields do |t|
      t.string :input_type, limit: 50, null: false
      t.string :machine_name, limit: 500, null: false
      t.references :customizable, polymorphic: true, null: false
      t.integer :order, default: 1, null: false
      t.string :title, limit: 500, null: false
      t.text :description
      t.jsonb :metadata, default: {}, null: false
      t.boolean :popular, default: false, null: false
      t.boolean :list, default: false, null: false
      t.boolean :required, default: false, null: false
      t.string :access_key, limit: 1
      t.timestamps
    end

    add_index :custom_fields, :machine_name

    create_table :custom_field_data_items do |t|
      t.references :custom_field, null: false, foreign_key: true
      t.integer :time_entry_id, null: false
      t.text :value
      t.jsonb :value_json, default: [], null: false
      t.timestamps
    end

    add_index :custom_field_data_items, :time_entry_id
  end
end
