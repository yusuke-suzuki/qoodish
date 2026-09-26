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

ActiveRecord::Schema[8.1].define(version: 2026_09_26_145115) do
  create_table "bookmarks", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "map_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["map_id", "user_id"], name: "index_bookmarks_on_map_id_and_user_id", unique: true
    t.index ["map_id"], name: "index_bookmarks_on_map_id"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "chapter_revision_images", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "chapter_revision_id", null: false
    t.datetime "created_at", null: false
    t.bigint "image_id", null: false
    t.datetime "updated_at", null: false
    t.index ["chapter_revision_id", "image_id"], name: "idx_on_chapter_revision_id_image_id_9e3b64d6f1", unique: true
    t.index ["chapter_revision_id"], name: "index_chapter_revision_images_on_chapter_revision_id"
    t.index ["image_id"], name: "index_chapter_revision_images_on_image_id"
  end

  create_table "chapter_revisions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "chapter_id", null: false
    t.json "content", null: false
    t.datetime "created_at", null: false
    t.json "map_features", null: false
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["chapter_id", "id"], name: "index_chapter_revisions_on_chapter_id_and_id"
    t.index ["chapter_id"], name: "index_chapter_revisions_on_chapter_id"
    t.index ["user_id"], name: "index_chapter_revisions_on_user_id"
  end

  create_table "chapters", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.json "content", null: false
    t.datetime "created_at", null: false
    t.bigint "current_revision_id"
    t.bigint "journey_id"
    t.json "map_features", null: false
    t.bigint "map_id"
    t.string "status", default: "draft", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["current_revision_id"], name: "index_chapters_on_current_revision_id"
    t.index ["journey_id"], name: "index_chapters_on_journey_id", unique: true
    t.index ["map_id"], name: "index_chapters_on_map_id"
    t.index ["status", "created_at"], name: "index_chapters_on_status_and_created_at"
    t.index ["user_id", "status"], name: "index_chapters_on_user_id_and_status"
  end

  create_table "coauthorship_invitations", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "invitee_id", null: false
    t.bigint "inviter_id", null: false
    t.bigint "map_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["invitee_id", "status"], name: "index_coauthorship_invitations_on_invitee_id_and_status"
    t.index ["invitee_id"], name: "index_coauthorship_invitations_on_invitee_id"
    t.index ["inviter_id"], name: "index_coauthorship_invitations_on_inviter_id"
    t.index ["map_id", "invitee_id"], name: "index_coauthorship_invitations_on_map_id_and_invitee_id"
    t.index ["map_id"], name: "index_coauthorship_invitations_on_map_id"
  end

  create_table "coauthorships", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "map_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["map_id", "user_id"], name: "index_coauthorships_on_map_id_and_user_id", unique: true
    t.index ["map_id"], name: "index_coauthorships_on_map_id"
    t.index ["user_id"], name: "index_coauthorships_on_user_id"
  end

  create_table "comment_revisions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "comment_id", null: false
    t.datetime "created_at", null: false
    t.string "status", default: "published", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["comment_id", "id"], name: "index_comment_revisions_on_comment_id_and_id"
    t.index ["comment_id"], name: "index_comment_revisions_on_comment_id"
    t.index ["user_id"], name: "index_comment_revisions_on_user_id"
  end

  create_table "comments", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "body", null: false
    t.bigint "commentable_id", null: false
    t.string "commentable_type", null: false
    t.datetime "created_at", null: false
    t.bigint "current_revision_id"
    t.string "status", default: "published", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"
    t.index ["current_revision_id"], name: "index_comments_on_current_revision_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "devices", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "registration_token", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["registration_token"], name: "index_devices_on_registration_token"
    t.index ["user_id", "registration_token"], name: "index_devices_on_user_id_and_registration_token", unique: true
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "featured_maps", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "map_id", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at", "map_id"], name: "index_featured_maps_on_created_at_and_map_id"
    t.index ["map_id"], name: "index_featured_maps_on_map_id"
  end

  create_table "images", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.bigint "user_id", null: false
    t.index ["url"], name: "index_images_on_url", unique: true
    t.index ["user_id"], name: "index_images_on_user_id"
  end

  create_table "journal_bookmarks", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "journal_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["journal_id", "user_id"], name: "index_journal_bookmarks_on_journal_id_and_user_id", unique: true
    t.index ["journal_id"], name: "index_journal_bookmarks_on_journal_id"
    t.index ["user_id"], name: "index_journal_bookmarks_on_user_id"
  end

  create_table "journal_revisions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.bigint "journal_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["journal_id", "id"], name: "index_journal_revisions_on_journal_id_and_id"
    t.index ["journal_id"], name: "index_journal_revisions_on_journal_id"
    t.index ["user_id"], name: "index_journal_revisions_on_user_id"
  end

  create_table "journals", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "current_revision_id"
    t.string "description"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["current_revision_id"], name: "index_journals_on_current_revision_id"
    t.index ["user_id"], name: "index_journals_on_user_id", unique: true
  end

  create_table "journey_checkin_revision_images", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "image_id", null: false
    t.bigint "journey_checkin_revision_id", null: false
    t.datetime "updated_at", null: false
    t.index ["image_id"], name: "index_journey_checkin_revision_images_on_image_id"
    t.index ["journey_checkin_revision_id", "image_id"], name: "index_checkin_revision_images_on_revision_id_and_image_id", unique: true
    t.index ["journey_checkin_revision_id"], name: "idx_on_journey_checkin_revision_id_79ea77d6c2"
  end

  create_table "journey_checkin_revisions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "checked_in_at", null: false
    t.datetime "created_at", null: false
    t.bigint "journey_checkin_id", null: false
    t.text "note"
    t.string "status", default: "recorded", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["journey_checkin_id", "id"], name: "index_journey_checkin_revisions_on_journey_checkin_id_and_id"
    t.index ["journey_checkin_id"], name: "index_journey_checkin_revisions_on_journey_checkin_id"
    t.index ["user_id"], name: "index_journey_checkin_revisions_on_user_id"
  end

  create_table "journey_checkins", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "checked_in_at", null: false
    t.datetime "created_at", null: false
    t.bigint "current_revision_id"
    t.bigint "journey_id", null: false
    t.decimal "latitude", precision: 16, scale: 6, null: false
    t.decimal "longitude", precision: 16, scale: 6, null: false
    t.string "name", null: false
    t.text "note"
    t.bigint "pin_id"
    t.string "status", default: "recorded", null: false
    t.datetime "updated_at", null: false
    t.index ["current_revision_id"], name: "index_journey_checkins_on_current_revision_id"
    t.index ["journey_id", "pin_id"], name: "index_journey_checkins_on_journey_id_and_pin_id", unique: true
    t.index ["pin_id"], name: "index_journey_checkins_on_pin_id"
  end

  create_table "journeys", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "encoded_path", size: :medium
    t.datetime "finished_at"
    t.bigint "map_id"
    t.datetime "started_at"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["map_id"], name: "index_journeys_on_map_id"
    t.index ["user_id", "map_id", "finished_at"], name: "index_journeys_on_user_id_and_map_id_and_finished_at"
  end

  create_table "map_revision_images", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "image_id", null: false
    t.bigint "map_revision_id", null: false
    t.datetime "updated_at", null: false
    t.index ["image_id"], name: "index_map_revision_images_on_image_id"
    t.index ["map_revision_id", "image_id"], name: "index_map_revision_images_on_map_revision_id_and_image_id", unique: true
    t.index ["map_revision_id"], name: "index_map_revision_images_on_map_revision_id"
  end

  create_table "map_revisions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.decimal "latitude", precision: 16, scale: 6, null: false
    t.decimal "longitude", precision: 16, scale: 6, null: false
    t.bigint "map_id", null: false
    t.string "name", null: false
    t.boolean "private", default: true, null: false
    t.string "status", default: "published", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["map_id", "id"], name: "index_map_revisions_on_map_id_and_id"
    t.index ["map_id"], name: "index_map_revisions_on_map_id"
    t.index ["user_id"], name: "index_map_revisions_on_user_id"
  end

  create_table "maps", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "base_id_val"
    t.string "base_name"
    t.datetime "created_at", null: false
    t.bigint "current_revision_id"
    t.string "description", null: false
    t.boolean "invitable", default: false
    t.decimal "latitude", precision: 16, scale: 6, default: "0.0", null: false
    t.decimal "longitude", precision: 16, scale: 6, default: "0.0", null: false
    t.string "name", null: false
    t.boolean "private", default: true
    t.boolean "shared", default: false
    t.string "status", default: "published", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["current_revision_id"], name: "index_maps_on_current_revision_id"
    t.index ["status", "created_at"], name: "index_maps_on_status_and_created_at"
    t.index ["user_id"], name: "index_maps_on_user_id"
  end

  create_table "milestones", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "journey_id", null: false
    t.decimal "latitude", precision: 16, scale: 6, null: false
    t.decimal "longitude", precision: 16, scale: 6, null: false
    t.string "name", null: false
    t.bigint "pin_id"
    t.integer "position", null: false
    t.datetime "updated_at", null: false
    t.index ["journey_id", "pin_id"], name: "index_milestones_on_journey_id_and_pin_id", unique: true
    t.index ["journey_id", "position"], name: "index_milestones_on_journey_id_and_position"
    t.index ["pin_id"], name: "index_milestones_on_pin_id"
  end

  create_table "moderation_decisions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "author_id"
    t.text "content_snapshot"
    t.datetime "created_at", null: false
    t.bigint "moderatable_id", null: false
    t.string "moderatable_type", null: false
    t.bigint "moderator_id"
    t.string "outcome", null: false
    t.text "reason", null: false
    t.bigint "reviewed_revision_id"
    t.bigint "staff_member_id"
    t.index ["author_id"], name: "index_moderation_decisions_on_author_id"
    t.index ["moderatable_type", "moderatable_id", "created_at"], name: "index_moderation_decisions_on_moderatable_and_time"
    t.index ["moderator_id"], name: "index_moderation_decisions_on_moderator_id"
    t.index ["staff_member_id"], name: "index_moderation_decisions_on_staff_member_id"
  end

  create_table "notifications", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "key"
    t.bigint "notifiable_id"
    t.string "notifiable_type"
    t.bigint "notifier_id"
    t.string "notifier_type"
    t.boolean "read", default: false
    t.bigint "recipient_id"
    t.string "recipient_type"
    t.datetime "updated_at", null: false
    t.index ["notifiable_id", "notifiable_type"], name: "index_notifications_on_notifiable_id_and_notifiable_type"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["notifier_id", "notifier_type"], name: "index_notifications_on_notifier_id_and_notifier_type"
    t.index ["notifier_type", "notifier_id"], name: "index_notifications_on_notifier_type_and_notifier_id"
    t.index ["recipient_id", "recipient_type"], name: "index_notifications_on_recipient_id_and_recipient_type"
    t.index ["recipient_type", "recipient_id"], name: "index_notifications_on_recipient_type_and_recipient_id"
  end

  create_table "pin_revision_images", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "image_id", null: false
    t.bigint "pin_revision_id", null: false
    t.datetime "updated_at", null: false
    t.index ["image_id"], name: "index_pin_revision_images_on_image_id"
    t.index ["pin_revision_id", "image_id"], name: "index_pin_revision_images_on_pin_revision_id_and_image_id", unique: true
    t.index ["pin_revision_id"], name: "index_pin_revision_images_on_pin_revision_id"
  end

  create_table "pin_revisions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "comment", null: false
    t.datetime "created_at", null: false
    t.decimal "latitude", precision: 16, scale: 6, null: false
    t.decimal "longitude", precision: 16, scale: 6, null: false
    t.text "name", null: false
    t.bigint "pin_id", null: false
    t.string "status", default: "published", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["pin_id", "id"], name: "index_pin_revisions_on_pin_id_and_id"
    t.index ["pin_id"], name: "index_pin_revisions_on_pin_id"
    t.index ["user_id"], name: "index_pin_revisions_on_user_id"
  end

  create_table "pins", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.text "comment", null: false
    t.datetime "created_at", null: false
    t.bigint "current_revision_id"
    t.decimal "latitude", precision: 16, scale: 6, null: false
    t.decimal "longitude", precision: 16, scale: 6, null: false
    t.bigint "map_id", null: false
    t.text "name", null: false
    t.bigint "spot_id"
    t.string "status", default: "published", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["created_at"], name: "index_pins_on_created_at"
    t.index ["current_revision_id"], name: "index_pins_on_current_revision_id"
    t.index ["map_id"], name: "index_pins_on_map_id"
    t.index ["status", "created_at"], name: "index_pins_on_status_and_created_at"
    t.index ["user_id"], name: "index_pins_on_user_id"
  end

  create_table "reports", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "category", null: false
    t.text "content_snapshot"
    t.datetime "created_at", null: false
    t.text "details"
    t.text "evidence_url"
    t.string "locale", null: false
    t.bigint "moderatable_id", null: false
    t.string "moderatable_type", null: false
    t.bigint "reported_revision_id"
    t.string "reporter_email"
    t.bigint "reporter_id"
    t.index ["moderatable_type", "moderatable_id"], name: "index_reports_on_moderatable"
    t.index ["reporter_email", "moderatable_type", "moderatable_id"], name: "index_reports_on_reporter_email_and_moderatable", unique: true
    t.index ["reporter_id", "moderatable_type", "moderatable_id"], name: "index_reports_on_reporter_and_moderatable", unique: true
    t.index ["reporter_id"], name: "index_reports_on_reporter_id"
  end

  create_table "role_permissions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "permission", null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id", "permission"], name: "index_role_permissions_on_role_id_and_permission", unique: true
  end

  create_table "roles", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "staff_member_roles", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "role_id", null: false
    t.bigint "staff_member_id", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_staff_member_roles_on_role_id"
    t.index ["staff_member_id", "role_id"], name: "index_staff_member_roles_on_staff_member_id_and_role_id", unique: true
  end

  create_table "staff_members", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.datetime "revoked_at"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_staff_members_on_email", unique: true
  end

  create_table "user_preferences", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.json "web_push", null: false
    t.index ["user_id"], name: "index_user_preferences_on_user_id"
  end

  create_table "user_revisions", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "biography"
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "id"], name: "index_user_revisions_on_user_id_and_id"
    t.index ["user_id"], name: "index_user_revisions_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "biography"
    t.datetime "created_at", null: false
    t.bigint "current_revision_id"
    t.string "email"
    t.bigint "image_id"
    t.string "locale"
    t.string "name"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["current_revision_id"], name: "index_users_on_current_revision_id"
    t.index ["image_id"], name: "index_users_on_image_id"
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  create_table "votes", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "votable_id"
    t.string "votable_type"
    t.boolean "vote_flag"
    t.string "vote_scope"
    t.integer "vote_weight"
    t.bigint "voter_id"
    t.string "voter_type"
    t.index ["votable_id", "votable_type", "vote_scope"], name: "index_votes_on_votable_id_and_votable_type_and_vote_scope"
    t.index ["votable_type", "votable_id", "voter_type", "voter_id"], name: "index_votes_on_votable_and_voter", unique: true
    t.index ["votable_type", "votable_id"], name: "index_votes_on_votable_type_and_votable_id"
    t.index ["voter_id", "voter_type", "vote_scope"], name: "index_votes_on_voter_id_and_voter_type_and_vote_scope"
    t.index ["voter_type", "voter_id"], name: "index_votes_on_voter_type_and_voter_id"
  end

  add_foreign_key "bookmarks", "maps"
  add_foreign_key "bookmarks", "users"
  add_foreign_key "chapter_revision_images", "chapter_revisions"
  add_foreign_key "chapter_revision_images", "images"
  add_foreign_key "chapter_revisions", "chapters"
  add_foreign_key "chapter_revisions", "users"
  add_foreign_key "chapters", "chapter_revisions", column: "current_revision_id"
  add_foreign_key "chapters", "journeys"
  add_foreign_key "chapters", "maps"
  add_foreign_key "chapters", "users"
  add_foreign_key "coauthorship_invitations", "maps"
  add_foreign_key "coauthorship_invitations", "users", column: "invitee_id"
  add_foreign_key "coauthorship_invitations", "users", column: "inviter_id"
  add_foreign_key "coauthorships", "maps"
  add_foreign_key "coauthorships", "users"
  add_foreign_key "comment_revisions", "comments"
  add_foreign_key "comment_revisions", "users"
  add_foreign_key "comments", "comment_revisions", column: "current_revision_id"
  add_foreign_key "featured_maps", "maps"
  add_foreign_key "images", "users"
  add_foreign_key "journal_bookmarks", "journals"
  add_foreign_key "journal_bookmarks", "users"
  add_foreign_key "journal_revisions", "journals"
  add_foreign_key "journal_revisions", "users"
  add_foreign_key "journals", "journal_revisions", column: "current_revision_id"
  add_foreign_key "journals", "users"
  add_foreign_key "journey_checkin_revision_images", "images"
  add_foreign_key "journey_checkin_revision_images", "journey_checkin_revisions"
  add_foreign_key "journey_checkin_revisions", "journey_checkins"
  add_foreign_key "journey_checkin_revisions", "users"
  add_foreign_key "journey_checkins", "journey_checkin_revisions", column: "current_revision_id"
  add_foreign_key "journey_checkins", "journeys"
  add_foreign_key "journey_checkins", "pins"
  add_foreign_key "journeys", "maps"
  add_foreign_key "journeys", "users"
  add_foreign_key "map_revision_images", "images"
  add_foreign_key "map_revision_images", "map_revisions"
  add_foreign_key "map_revisions", "maps"
  add_foreign_key "map_revisions", "users"
  add_foreign_key "maps", "map_revisions", column: "current_revision_id"
  add_foreign_key "maps", "users"
  add_foreign_key "milestones", "journeys"
  add_foreign_key "milestones", "pins"
  add_foreign_key "moderation_decisions", "staff_members"
  add_foreign_key "moderation_decisions", "users", column: "author_id"
  add_foreign_key "moderation_decisions", "users", column: "moderator_id"
  add_foreign_key "pin_revision_images", "images"
  add_foreign_key "pin_revision_images", "pin_revisions"
  add_foreign_key "pin_revisions", "pins"
  add_foreign_key "pin_revisions", "users"
  add_foreign_key "pins", "maps"
  add_foreign_key "pins", "pin_revisions", column: "current_revision_id"
  add_foreign_key "pins", "users"
  add_foreign_key "reports", "users", column: "reporter_id"
  add_foreign_key "role_permissions", "roles"
  add_foreign_key "staff_member_roles", "roles"
  add_foreign_key "staff_member_roles", "staff_members"
  add_foreign_key "user_preferences", "users"
  add_foreign_key "user_revisions", "users"
  add_foreign_key "users", "images", on_delete: :nullify
  add_foreign_key "users", "user_revisions", column: "current_revision_id"
end
