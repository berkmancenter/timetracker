# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2021_08_19_193754) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "time_entries", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "category", limit: 100, null: false
    t.string "project", limit: 100
    t.decimal "decimal_time", precision: 4, scale: 2
    t.string "description", limit: 5000
    t.date "entry_date", null: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.index ["category"], name: "index_time_entries_on_category"
    t.index ["entry_date"], name: "index_time_entries_on_entry_date"
    t.index ["project"], name: "index_time_entries_on_project"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "username", limit: 100, null: false
    t.boolean "superadmin", default: false
    t.datetime "created_at", precision: nil
    t.datetime "updated_at", precision: nil
    t.string "email", limit: 255
    t.index ["superadmin"], name: "index_users_on_superadmin"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

end
