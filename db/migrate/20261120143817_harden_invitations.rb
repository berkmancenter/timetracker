class HardenInvitations < ActiveRecord::Migration[7.0]
  def up
    execute <<~SQL.squish
      UPDATE invitations
      SET expiration = created_at + INTERVAL '7 days'
      WHERE expiration IS NULL
    SQL

    duplicate_codes = select_value(<<~SQL.squish).to_i
      SELECT COUNT(*)
      FROM (
        SELECT code
        FROM invitations
        GROUP BY code
        HAVING COUNT(*) > 1
      ) duplicates
    SQL
    if duplicate_codes.positive?
      raise ActiveRecord::MigrationError,
            "Cannot add invitation code constraint: #{duplicate_codes} duplicate codes exist"
    end

    change_column_null :invitations, :expiration, false
    add_index :invitations, :code, unique: true
  end

  def down
    remove_index :invitations, :code
    change_column_null :invitations, :expiration, true
  end
end
