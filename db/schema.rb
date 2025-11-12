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

ActiveRecord::Schema[7.1].define(version: 2025_11_12_152417) do
  create_table "active_storage_attachments", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb3", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "archived_results", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.integer "diff_count"
    t.bigint "child_project_id", null: false
    t.string "file_a_id"
    t.string "file_b_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "preview_data"
    t.index ["child_project_id"], name: "index_archived_results_on_child_project_id"
  end

  create_table "logs", charset: "utf8mb3", force: :cascade do |t|
    t.string "action_type", null: false
    t.text "description"
    t.bigint "user_id", null: false
    t.bigint "project_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["project_id"], name: "index_logs_on_project_id"
    t.index ["user_id"], name: "index_logs_on_user_id"
  end

  create_table "parent_projects", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_parent_projects_on_user_id"
  end

  create_table "projects", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "parent_project_id", null: false
    t.string "name", null: false
    t.string "status"
    t.boolean "is_locked", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_project_id"], name: "index_projects_on_parent_project_id"
  end

  create_table "templates", charset: "utf8mb3", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "user_id", null: false
    t.json "range"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.json "mapping"
    t.index ["user_id"], name: "index_templates_on_user_id"
  end

  create_table "trace_results", charset: "utf8mb3", force: :cascade do |t|
    t.bigint "archived_result_id", null: false
    t.string "key", null: false
    t.string "flag", null: false
    t.text "comment"
    t.json "target_cell"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["archived_result_id"], name: "index_trace_results_on_archived_result_id"
  end

  create_table "users", charset: "utf8mb3", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "personal_num", default: "", null: false
    t.string "name", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["personal_num"], name: "index_users_on_personal_num", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "archived_results", "projects", column: "child_project_id"
  add_foreign_key "logs", "projects"
  add_foreign_key "logs", "users"
  add_foreign_key "parent_projects", "users"
  add_foreign_key "projects", "parent_projects"
  add_foreign_key "templates", "users"
  add_foreign_key "trace_results", "archived_results"
end
