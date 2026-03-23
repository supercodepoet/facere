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

ActiveRecord::Schema[8.1].define(version: 2026_03_23_183304) do
  create_table "action_text_rich_texts", force: :cascade do |t|
    t.text "body"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.datetime "updated_at", null: false
    t.index ["record_type", "record_id", "name"], name: "index_action_text_rich_texts_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "checklist_items", force: :cascade do |t|
    t.boolean "completed", default: false, null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "todo_item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["todo_item_id"], name: "index_checklist_items_on_todo_item_id"
  end

  create_table "comment_likes", force: :cascade do |t|
    t.integer "comment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["comment_id", "user_id"], name: "index_comment_likes_on_comment_id_and_user_id", unique: true
    t.index ["comment_id"], name: "index_comment_likes_on_comment_id"
    t.index ["user_id"], name: "index_comment_likes_on_user_id"
  end

  create_table "comments", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "edited_at"
    t.integer "likes_count", default: 0
    t.integer "parent_id"
    t.integer "todo_item_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["todo_item_id"], name: "index_comments_on_todo_item_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "item_assignees", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "todo_item_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["todo_item_id", "user_id"], name: "index_item_assignees_on_todo_item_id_and_user_id", unique: true
    t.index ["todo_item_id"], name: "index_item_assignees_on_todo_item_id"
    t.index ["user_id"], name: "index_item_assignees_on_user_id"
  end

  create_table "item_tags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "tag_id", null: false
    t.integer "todo_item_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_item_tags_on_tag_id"
    t.index ["todo_item_id", "tag_id"], name: "index_item_tags_on_todo_item_id_and_tag_id", unique: true
  end

  create_table "list_collaborators", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "role", default: "editor", null: false
    t.integer "todo_list_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["todo_list_id", "user_id"], name: "index_list_collaborators_on_todo_list_id_and_user_id", unique: true
    t.index ["todo_list_id"], name: "index_list_collaborators_on_todo_list_id"
    t.index ["user_id"], name: "index_list_collaborators_on_user_id"
  end

  create_table "list_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "expires_at", null: false
    t.integer "invited_by_id", null: false
    t.string "role", default: "editor", null: false
    t.string "status", default: "pending", null: false
    t.integer "todo_list_id", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_list_invitations_on_email"
    t.index ["invited_by_id"], name: "index_list_invitations_on_invited_by_id"
    t.index ["status", "expires_at"], name: "index_list_invitations_on_status_and_expires_at"
    t.index ["todo_list_id", "email"], name: "index_list_invitations_unique_pending", unique: true, where: "status = 'pending'"
    t.index ["todo_list_id"], name: "index_list_invitations_on_todo_list_id"
  end

  create_table "notify_people", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "todo_item_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["todo_item_id", "user_id"], name: "index_notify_people_on_todo_item_id_and_user_id", unique: true
    t.index ["todo_item_id"], name: "index_notify_people_on_todo_item_id"
    t.index ["user_id"], name: "index_notify_people_on_user_id"
  end

  create_table "oauth_identities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["provider", "uid"], name: "index_oauth_identities_on_provider_and_uid", unique: true
    t.index ["user_id"], name: "index_oauth_identities_on_user_id"
  end

  create_table "recovery_codes", force: :cascade do |t|
    t.string "code_digest", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "used_at"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_recovery_codes_on_user_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "tags", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index "user_id, lower(name)", name: "index_tags_on_user_id_and_lower_name", unique: true
    t.index ["user_id"], name: "index_tags_on_user_id"
  end

  create_table "todo_items", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.boolean "completed", default: false, null: false
    t.datetime "created_at", null: false
    t.date "due_date"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.string "priority", default: "medium", null: false
    t.string "status", default: "todo", null: false
    t.integer "todo_list_id", null: false
    t.integer "todo_section_id"
    t.datetime "updated_at", null: false
    t.index ["todo_list_id"], name: "index_todo_items_on_todo_list_id"
    t.index ["todo_section_id"], name: "index_todo_items_on_todo_section_id"
  end

  create_table "todo_lists", force: :cascade do |t|
    t.string "color", default: "purple", null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "icon"
    t.string "name", null: false
    t.string "template", default: "blank", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index "user_id, lower(name)", name: "index_todo_lists_on_user_id_and_lower_name", unique: true
    t.index ["user_id"], name: "index_todo_lists_on_user_id"
  end

  create_table "todo_sections", force: :cascade do |t|
    t.boolean "archived", default: false, null: false
    t.datetime "created_at", null: false
    t.string "icon"
    t.string "name", null: false
    t.integer "position", default: 0, null: false
    t.integer "todo_list_id", null: false
    t.datetime "updated_at", null: false
    t.index ["todo_list_id"], name: "index_todo_sections_on_todo_list_id"
  end

  create_table "two_factor_credentials", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.string "otp_secret", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_two_factor_credentials_on_user_id", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.datetime "email_verification_grace_expires_at"
    t.datetime "email_verified_at"
    t.integer "failed_login_attempts", default: 0, null: false
    t.datetime "locked_until"
    t.integer "lockout_count", default: 0, null: false
    t.string "name", null: false
    t.string "password_digest"
    t.datetime "terms_accepted_at"
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "checklist_items", "todo_items"
  add_foreign_key "comment_likes", "comments"
  add_foreign_key "comment_likes", "users"
  add_foreign_key "comments", "todo_items"
  add_foreign_key "comments", "users"
  add_foreign_key "item_assignees", "todo_items"
  add_foreign_key "item_assignees", "users"
  add_foreign_key "item_tags", "tags"
  add_foreign_key "item_tags", "todo_items"
  add_foreign_key "list_collaborators", "todo_lists"
  add_foreign_key "list_collaborators", "users"
  add_foreign_key "list_invitations", "todo_lists"
  add_foreign_key "list_invitations", "users", column: "invited_by_id"
  add_foreign_key "notify_people", "todo_items"
  add_foreign_key "notify_people", "users"
  add_foreign_key "oauth_identities", "users"
  add_foreign_key "recovery_codes", "users"
  add_foreign_key "sessions", "users"
  add_foreign_key "tags", "users"
  add_foreign_key "todo_items", "todo_lists"
  add_foreign_key "todo_items", "todo_sections"
  add_foreign_key "todo_lists", "users"
  add_foreign_key "todo_sections", "todo_lists"
  add_foreign_key "two_factor_credentials", "users"
end
