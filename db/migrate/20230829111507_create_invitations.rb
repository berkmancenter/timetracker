class CreateInvitations < ActiveRecord::Migration[7.0]
  def change
    create_table :invitations do |t|
      t.string :code, null: false
      t.string :email
      t.datetime :expiration
      t.boolean :used, default: false, null: false
      t.references :timesheet, foreign_key: true
      t.references :sender, null: false
      t.references :used_by
      t.string :itype, default: 'single', null: false

      t.timestamps
    end

    add_foreign_key :invitations, :users, column: :sender_id, primary_key: :id
    add_foreign_key :invitations, :users, column: :used_by_id, primary_key: :id
  end
end
