class AddRoleToInvitation < ActiveRecord::Migration[7.0]
  def up
    add_column :invitations, :role, :string, default: 'user', null: false

    execute <<-SQL
      ALTER TABLE invitations
      ADD CONSTRAINT valid_role_check
      CHECK (role IN ('admin', 'user'))
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE invitations
      DROP CONSTRAINT IF EXISTS valid_role_check
    SQL

    remove_column :invitations, :role
  end
end
