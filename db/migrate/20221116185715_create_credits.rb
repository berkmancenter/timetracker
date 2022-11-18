class CreateCredits < ActiveRecord::Migration[7.0]
  def change
    create_table :credits do |t|
      t.column :amount, :decimal, precision: 6, scale: 2
      t.references :user
      t.references :period

      t.timestamps
    end
  end
end
