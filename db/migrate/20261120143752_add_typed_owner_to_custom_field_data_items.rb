class AddTypedOwnerToCustomFieldDataItems < ActiveRecord::Migration[7.0]
  def up
    rename_column :custom_field_data_items, :item_id, :owner_id
    change_column :custom_field_data_items, :owner_id, :bigint
    add_column :custom_field_data_items, :owner_type, :string

    execute <<~SQL.squish
      UPDATE custom_field_data_items AS data_items
      SET owner_type = CASE custom_fields.customizable_type
        WHEN 'Timesheet' THEN 'TimeEntry'
        WHEN 'Period' THEN 'User'
      END
      FROM custom_fields
      WHERE custom_fields.id = data_items.custom_field_id
    SQL

    unclassified_count = select_value(<<~SQL.squish).to_i
      SELECT COUNT(*)
      FROM custom_field_data_items
      WHERE owner_type IS NULL
    SQL
    if unclassified_count.positive?
      raise ActiveRecord::MigrationError,
            "Cannot classify #{unclassified_count} custom field data item owners"
    end

    change_column_null :custom_field_data_items, :owner_type, false
    remove_index :custom_field_data_items, column: :owner_id
    add_index :custom_field_data_items, %i[owner_type owner_id]
  end

  def down
    remove_index :custom_field_data_items, column: %i[owner_type owner_id]
    add_index :custom_field_data_items, :owner_id
    remove_column :custom_field_data_items, :owner_type
    change_column :custom_field_data_items, :owner_id, :integer
    rename_column :custom_field_data_items, :owner_id, :item_id
  end
end
