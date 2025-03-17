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

ActiveRecord::Schema[7.2].define(version: 2024_08_29_120025) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "credits", force: :cascade do |t|
    t.decimal "amount", precision: 6, scale: 2
    t.bigint "user_id"
    t.bigint "period_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["period_id"], name: "index_credits_on_period_id"
    t.index ["user_id"], name: "index_credits_on_user_id"
  end

  create_table "invitations", force: :cascade do |t|
    t.string "code", null: false
    t.string "email"
    t.datetime "expiration"
    t.boolean "used", default: false, null: false
    t.bigint "timesheet_id"
    t.bigint "sender_id", null: false
    t.bigint "used_by_id"
    t.string "itype", default: "single", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "role", default: "user", null: false
    t.index ["sender_id"], name: "index_invitations_on_sender_id"
    t.index ["timesheet_id"], name: "index_invitations_on_timesheet_id"
    t.index ["used_by_id"], name: "index_invitations_on_used_by_id"
    t.check_constraint "role::text = ANY (ARRAY['admin'::character varying, 'user'::character varying]::text[])", name: "valid_role_check"
  end

  create_table "periods", force: :cascade do |t|
    t.string "name", null: false
    t.date "from", null: false
    t.date "to", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "timesheet_id", null: false
    t.index ["timesheet_id"], name: "index_periods_on_timesheet_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.string "session_id", null: false
    t.text "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id", unique: true
    t.index ["updated_at"], name: "index_sessions_on_updated_at"
  end

  create_table "time_entries", force: :cascade do |t|
    t.bigint "user_id"
    t.decimal "decimal_time", precision: 4, scale: 2
    t.date "entry_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "timesheet_id", null: false
    t.index ["entry_date"], name: "index_time_entries_on_entry_date"
    t.index ["timesheet_id"], name: "index_time_entries_on_timesheet_id"
    t.index ["user_id"], name: "index_time_entries_on_user_id"
  end

  create_table "timesheet_field_data_items", force: :cascade do |t|
    t.integer "field_id", null: false
    t.integer "time_entry_id", null: false
    t.text "value"
    t.jsonb "value_json", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["field_id"], name: "timesheet_fields_data_item_field_id"
    t.index ["time_entry_id"], name: "custom_field_data_time_entry_id"
  end

  create_table "timesheet_fields", force: :cascade do |t|
    t.string "input_type", limit: 50, null: false
    t.string "machine_name", limit: 500, null: false
    t.integer "timesheet_id"
    t.integer "order", default: 1, null: false
    t.string "title", limit: 500, null: false
    t.text "description"
    t.jsonb "metadata", default: {}, null: false
    t.boolean "popular", default: false, null: false
    t.boolean "list", default: false, null: false
    t.boolean "required", default: false, null: false
    t.string "access_key", limit: 1
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["machine_name"], name: "timesheet_fields_machine_name"
    t.index ["timesheet_id"], name: "timesheet_fields_timesheet_id"
  end

  create_table "timesheets", force: :cascade do |t|
    t.string "name"
    t.string "public_code"
    t.string "uuid"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "username", limit: 100
    t.boolean "superadmin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "email"
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.string "password", default: "", null: false
    t.index ["superadmin"], name: "index_users_on_superadmin"
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  create_table "users_timesheets", force: :cascade do |t|
    t.bigint "user_id"
    t.bigint "timesheet_id"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["timesheet_id"], name: "index_users_timesheets_on_timesheet_id"
    t.index ["user_id", "timesheet_id"], name: "unique_user_timesheet", unique: true
    t.index ["user_id"], name: "index_users_timesheets_on_user_id"
  end

  add_foreign_key "invitations", "timesheets"
  add_foreign_key "invitations", "users", column: "sender_id"
  add_foreign_key "invitations", "users", column: "used_by_id"
  add_foreign_key "periods", "timesheets"
  add_foreign_key "time_entries", "timesheets"
  add_foreign_key "timesheet_field_data_items", "timesheet_fields", column: "field_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "users_timesheets", "timesheets"
  add_foreign_key "users_timesheets", "users"
end
