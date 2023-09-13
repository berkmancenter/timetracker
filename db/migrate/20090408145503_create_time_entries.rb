class CreateTimeEntries < ActiveRecord::Migration[7.0]
  def self.up
    create_table :time_entries do |t|
      t.references :user
      t.column :category, :string, limit: 100, null: false
      t.column :project, :string, limit: 100
      t.column :decimal_time, :decimal, precision: 4, scale: 2
      t.column :description, :string, limit: 5000
      t.column :entry_date, :date, null: false
      t.timestamps
    end
    add_index :time_entries, :category
    add_index :time_entries, :project
    add_index :time_entries, :entry_date
  end

  def self.down
    drop_table :time_entries
  end
end
