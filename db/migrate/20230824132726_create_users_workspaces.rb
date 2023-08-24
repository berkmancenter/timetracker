class CreateUsersWorkspaces < ActiveRecord::Migration[7.0]
  def change
    create_table :users_workspaces do |t|
      t.references :user, foreign_key: true
      t.references :workspace, foreign_key: true
      t.string :role

      t.timestamps
    end
  end
end
