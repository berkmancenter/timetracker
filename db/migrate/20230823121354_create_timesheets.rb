class CreateTimesheets < ActiveRecord::Migration[7.0]
  def change
    create_table :timesheets do |t|
      t.string :name
      t.string :public_code
      t.string :uuid

      t.timestamps
    end
  end
end
