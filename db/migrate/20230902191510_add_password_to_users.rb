class AddPasswordToUsers < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.string :password, null: false, default: ''
    end
  end
end
