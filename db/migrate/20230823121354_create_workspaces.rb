class CreateWorkspaces < ActiveRecord::Migration[7.0]
  def change
    create_table :workspaces do |t|
      t.string :name
      t.string :public_code

      t.timestamps
    end
  end
end