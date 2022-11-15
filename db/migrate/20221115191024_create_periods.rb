class CreatePeriods < ActiveRecord::Migration[7.0]
  def change
    create_table :periods do |t|
      t.string :name, null: false
      t.date :from, null: false
      t.date :to, null: false

      t.timestamps
    end
  end
end
