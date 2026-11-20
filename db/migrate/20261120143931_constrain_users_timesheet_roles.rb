class ConstrainUsersTimesheetRoles < ActiveRecord::Migration[7.0]
  VALID_ROLES = %w[admin user].freeze

  def up
    invalid_count = select_value(<<~SQL.squish).to_i
      SELECT COUNT(*)
      FROM users_timesheets
      WHERE role IS NULL OR role NOT IN ('admin', 'user')
    SQL
    if invalid_count.positive?
      raise ActiveRecord::MigrationError,
            "Cannot constrain users_timesheets roles: #{invalid_count} invalid rows exist"
    end

    change_column_null :users_timesheets, :role, false
    add_check_constraint :users_timesheets,
                         "role IN ('admin', 'user')",
                         name: 'users_timesheets_valid_role'
  end

  def down
    remove_check_constraint :users_timesheets, name: 'users_timesheets_valid_role'
    change_column_null :users_timesheets, :role, true
  end
end
