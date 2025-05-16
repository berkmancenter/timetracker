class MigrateCustomFieldsToCustomFields < ActiveRecord::Migration[7.2]
  def up
    custom_fields = execute("SELECT * FROM custom_fields")

    custom_fields.each do |field|
      # Insert into custom_fields
      execute <<-SQL.squish
        INSERT INTO custom_fields (
          input_type, machine_name, customizable_type, customizable_id,
          "order", title, description, metadata, popular, list, required,
          access_key, created_at, updated_at
        ) VALUES (
          #{connection.quote(field['input_type'])},
          #{connection.quote(field['machine_name'])},
          'Timesheet',
          #{field['timesheet_id'] || 'NULL'},
          #{field['order']},
          #{connection.quote(field['title'])},
          #{connection.quote(field['description'])},
          #{connection.quote(field['metadata'].to_json)},
          #{field['popular']},
          #{field['list']},
          #{field['required']},
          #{connection.quote(field['access_key'])},
          #{connection.quote(field['created_at'])},
          #{connection.quote(field['updated_at'])}
        )
      SQL
    end

    # Map old field IDs to new ones
    field_id_map = {}
    old_fields = execute("SELECT id, machine_name, timesheet_id FROM custom_fields")
    new_fields = execute("SELECT id, machine_name, customizable_id FROM custom_fields WHERE customizable_type = 'Timesheet'")
    old_fields.each do |old|
      new = new_fields.find { |n| n['machine_name'] == old['machine_name'] && n['customizable_id'] == old['timesheet_id'] }
      field_id_map[old['id']] = new['id'] if new
    end

    # Migrate field data
    data_items = execute("SELECT * FROM custom_field_data_items")
    data_items.each do |item|
      new_field_id = field_id_map[item['field_id']]
      next unless new_field_id

      execute <<-SQL.squish
        INSERT INTO custom_field_data_items (
          custom_field_id, time_entry_id, value, value_json, created_at, updated_at
        ) VALUES (
          #{new_field_id},
          #{item['time_entry_id']},
          #{connection.quote(item['value'])},
          #{connection.quote(item['value_json'].to_json)},
          #{connection.quote(item['created_at'])},
          #{connection.quote(item['updated_at'])}
        )
      SQL
    end
  end

  def down
    # Optional: implement if you need rollback
  end
end
