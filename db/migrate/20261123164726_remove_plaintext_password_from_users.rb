class RemovePlaintextPasswordFromUsers < ActiveRecord::Migration[7.0]
  def up
    # Devise only stores bcrypt hashes (they start with "$2"), anything else
    # is a plaintext random password saved by the old set_random_password.
    execute <<~SQL
      UPDATE users
      SET encrypted_password = ''
      WHERE encrypted_password <> '' AND encrypted_password NOT LIKE '$2%'
    SQL

    remove_column :users, :password
  end

  def down
    add_column :users, :password, :string, null: false, default: ''
  end
end
