class AddMissingIndexesAndForeignKeys < ActiveRecord::Migration[8.1]
  def up
    remove_orphaned_rows

    ensure_no_duplicates!(
      'users',
      'LOWER(email)',
      "WHERE email IS NOT NULL AND email <> ''"
    )
    ensure_no_duplicates!('timesheets', 'uuid', 'WHERE uuid IS NOT NULL')
    ensure_no_duplicates!('credits', 'user_id, period_id')
    ensure_no_duplicates!('custom_field_data_items', 'custom_field_id, owner_type, owner_id')
    ensure_no_duplicates!('custom_fields', 'customizable_type, customizable_id, machine_name')

    add_index :users, :email
    add_index :users,
              'LOWER(email)',
              unique: true,
              where: "email IS NOT NULL AND email <> ''",
              name: 'index_users_on_lower_email'

    add_index :timesheets, :uuid, unique: true

    add_index :time_entries, :user_id
    add_index :time_entries,
              %i[timesheet_id user_id entry_date],
              name: 'index_time_entries_on_timesheet_user_date'
    add_foreign_key :time_entries, :users

    add_index :credits, %i[user_id period_id], unique: true
    add_foreign_key :credits, :users
    add_foreign_key :credits, :periods

    add_index :custom_field_data_items,
              %i[custom_field_id owner_type owner_id],
              unique: true,
              name: 'index_cfdi_on_field_and_owner'

    add_index :custom_fields,
              %i[customizable_type customizable_id machine_name],
              unique: true,
              name: 'index_custom_fields_on_customizable_and_machine_name'
  end

  def down
    remove_index :custom_fields, name: 'index_custom_fields_on_customizable_and_machine_name'
    remove_index :custom_field_data_items, name: 'index_cfdi_on_field_and_owner'

    remove_foreign_key :credits, :periods
    remove_foreign_key :credits, :users
    remove_index :credits, %i[user_id period_id]

    remove_foreign_key :time_entries, :users
    remove_index :time_entries, name: 'index_time_entries_on_timesheet_user_date'
    remove_index :time_entries, :user_id

    remove_index :timesheets, :uuid

    remove_index :users, name: 'index_users_on_lower_email'
    remove_index :users, :email
  end

  private

  # Rows pointing to a deleted user or period can't be shown anywhere (all
  # queries join them), but they would stop the foreign keys from being added.
  # They are deleted for good, rolling back doesn't bring them back.
  def remove_orphaned_rows
    orphaned_entry_ids = <<~SQL
      SELECT time_entries.id
      FROM time_entries
      WHERE time_entries.user_id IS NOT NULL
        AND NOT EXISTS (SELECT 1 FROM users WHERE users.id = time_entries.user_id)
    SQL

    delete_rows('custom field values of orphaned time entries', <<~SQL)
      DELETE FROM custom_field_data_items
      WHERE owner_type = 'TimeEntry' AND owner_id IN (#{orphaned_entry_ids})
    SQL

    delete_rows('orphaned time entries', <<~SQL)
      DELETE FROM time_entries WHERE id IN (#{orphaned_entry_ids})
    SQL

    delete_rows('orphaned credits', <<~SQL)
      DELETE FROM credits
      WHERE (user_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM users WHERE users.id = credits.user_id))
         OR (period_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM periods WHERE periods.id = credits.period_id))
    SQL
  end

  def delete_rows(label, sql)
    deleted_count = exec_delete(sql.squish)
    say "Deleted #{deleted_count} #{label}" if deleted_count.positive?
  end

  def ensure_no_duplicates!(table, group_columns, where_clause = nil)
    duplicate_count = select_value(<<~SQL.squish).to_i
      SELECT COUNT(*)
      FROM (
        SELECT #{group_columns}
        FROM #{table}
        #{where_clause}
        GROUP BY #{group_columns}
        HAVING COUNT(*) > 1
      ) duplicates
    SQL

    return unless duplicate_count.positive?

    raise ActiveRecord::MigrationError,
          "Cannot add unique index on #{table}(#{group_columns}): #{duplicate_count} duplicate groups exist"
  end
end
