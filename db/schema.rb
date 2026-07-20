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

ActiveRecord::Schema[7.2].define(version: 2026_07_20_102542) do
  create_table "bookmarks", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "map_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["map_id", "user_id"], name: "index_bookmarks_on_map_id_and_user_id", unique: true
    t.index ["map_id"], name: "index_bookmarks_on_map_id"
    t.index ["user_id"], name: "index_bookmarks_on_user_id"
  end

  create_table "chapters", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "map_id"
    t.bigint "journey_id"
    t.string "title", null: false
    t.string "status", default: "draft", null: false
    t.json "content", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["journey_id"], name: "index_chapters_on_journey_id", unique: true
    t.index ["map_id"], name: "index_chapters_on_map_id"
    t.index ["user_id", "status"], name: "index_chapters_on_user_id_and_status"
  end

  create_table "coauthorship_invitations", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "map_id", null: false
    t.bigint "inviter_id", null: false
    t.bigint "invitee_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invitee_id", "status"], name: "index_coauthorship_invitations_on_invitee_id_and_status"
    t.index ["invitee_id"], name: "index_coauthorship_invitations_on_invitee_id"
    t.index ["inviter_id"], name: "index_coauthorship_invitations_on_inviter_id"
    t.index ["map_id", "invitee_id"], name: "index_coauthorship_invitations_on_map_id_and_invitee_id"
    t.index ["map_id"], name: "index_coauthorship_invitations_on_map_id"
  end

  create_table "coauthorships", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "map_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["map_id", "user_id"], name: "index_coauthorships_on_map_id_and_user_id", unique: true
    t.index ["map_id"], name: "index_coauthorships_on_map_id"
    t.index ["user_id"], name: "index_coauthorships_on_user_id"
  end

  create_table "comments", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "commentable_type", null: false
    t.bigint "commentable_id", null: false
    t.bigint "user_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_type", "commentable_id"], name: "index_comments_on_commentable_type_and_commentable_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "devices", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "registration_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["registration_token"], name: "index_devices_on_registration_token"
    t.index ["user_id", "registration_token"], name: "index_devices_on_user_id_and_registration_token", unique: true
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "images", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "imageable_type"
    t.bigint "imageable_id"
    t.index ["imageable_type", "imageable_id"], name: "index_images_on_imageable"
    t.index ["url"], name: "index_images_on_url", unique: true
    t.index ["user_id"], name: "index_images_on_user_id"
  end

  create_table "inappropriate_contents", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "content_id_val", null: false
    t.string "content_type", null: false
    t.integer "reason_id_val", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_inappropriate_contents_on_user_id"
  end

  create_table "journey_checkins", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "journey_id", null: false
    t.bigint "review_id"
    t.string "name", null: false
    t.decimal "latitude", precision: 16, scale: 6, null: false
    t.decimal "longitude", precision: 16, scale: 6, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "note"
    t.datetime "checked_in_at", null: false
    t.index ["journey_id", "review_id"], name: "index_journey_checkins_on_journey_id_and_review_id", unique: true
    t.index ["review_id"], name: "index_journey_checkins_on_review_id"
  end

  create_table "journeys", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "map_id"
    t.datetime "started_at"
    t.datetime "finished_at"
    t.text "encoded_path", size: :medium
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["map_id"], name: "index_journeys_on_map_id"
    t.index ["user_id", "map_id", "finished_at"], name: "index_journeys_on_user_id_and_map_id_and_finished_at"
  end

  create_table "maps", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.string "description", null: false
    t.boolean "private", default: true
    t.boolean "invitable", default: false
    t.boolean "shared", default: false
    t.string "base_id_val"
    t.string "base_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "latitude", precision: 16, scale: 6, default: "0.0", null: false
    t.decimal "longitude", precision: 16, scale: 6, default: "0.0", null: false
    t.index ["user_id"], name: "index_maps_on_user_id"
  end

  create_table "milestones", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "journey_id", null: false
    t.bigint "review_id"
    t.integer "position", null: false
    t.string "name", null: false
    t.decimal "latitude", precision: 16, scale: 6, null: false
    t.decimal "longitude", precision: 16, scale: 6, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["journey_id", "position"], name: "index_milestones_on_journey_id_and_position"
    t.index ["journey_id", "review_id"], name: "index_milestones_on_journey_id_and_review_id", unique: true
    t.index ["review_id"], name: "index_milestones_on_review_id"
  end

  create_table "notifications", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "notifiable_type"
    t.bigint "notifiable_id"
    t.string "notifier_type"
    t.bigint "notifier_id"
    t.string "recipient_type"
    t.bigint "recipient_id"
    t.string "key"
    t.boolean "read", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["notifiable_id", "notifiable_type"], name: "index_notifications_on_notifiable_id_and_notifiable_type"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable_type_and_notifiable_id"
    t.index ["notifier_id", "notifier_type"], name: "index_notifications_on_notifier_id_and_notifier_type"
    t.index ["notifier_type", "notifier_id"], name: "index_notifications_on_notifier_type_and_notifier_id"
    t.index ["recipient_id", "recipient_type"], name: "index_notifications_on_recipient_id_and_recipient_type"
    t.index ["recipient_type", "recipient_id"], name: "index_notifications_on_recipient_type_and_recipient_id"
  end

  create_table "push_notifications", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "followed", default: false, null: false
    t.boolean "invited", default: false, null: false
    t.boolean "liked", default: false, null: false
    t.boolean "comment", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "coauthor_invited", default: false, null: false
    t.index ["user_id"], name: "index_push_notifications_on_user_id"
  end

  create_table "reviews", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "map_id", null: false
    t.text "comment", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "spot_id"
    t.decimal "latitude", precision: 16, scale: 6, null: false
    t.decimal "longitude", precision: 16, scale: 6, null: false
    t.text "name", null: false
    t.index ["map_id"], name: "index_reviews_on_map_id"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "biography"
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  create_table "votes", charset: "utf8mb4", collation: "utf8mb4_general_ci", force: :cascade do |t|
    t.string "votable_type"
    t.bigint "votable_id"
    t.string "voter_type"
    t.bigint "voter_id"
    t.boolean "vote_flag"
    t.string "vote_scope"
    t.integer "vote_weight"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["votable_id", "votable_type", "vote_scope"], name: "index_votes_on_votable_id_and_votable_type_and_vote_scope"
    t.index ["votable_type", "votable_id"], name: "index_votes_on_votable_type_and_votable_id"
    t.index ["voter_id", "voter_type", "vote_scope"], name: "index_votes_on_voter_id_and_voter_type_and_vote_scope"
    t.index ["voter_type", "voter_id"], name: "index_votes_on_voter_type_and_voter_id"
  end

  add_foreign_key "bookmarks", "maps"
  add_foreign_key "bookmarks", "users"
  add_foreign_key "chapters", "journeys"
  add_foreign_key "chapters", "maps"
  add_foreign_key "chapters", "users"
  add_foreign_key "coauthorship_invitations", "maps"
  add_foreign_key "coauthorship_invitations", "users", column: "invitee_id"
  add_foreign_key "coauthorship_invitations", "users", column: "inviter_id"
  add_foreign_key "coauthorships", "maps"
  add_foreign_key "coauthorships", "users"
  add_foreign_key "images", "users"
  add_foreign_key "journey_checkins", "journeys"
  add_foreign_key "journey_checkins", "reviews"
  add_foreign_key "journeys", "maps"
  add_foreign_key "journeys", "users"
  add_foreign_key "maps", "users"
  add_foreign_key "milestones", "journeys"
  add_foreign_key "milestones", "reviews"
  add_foreign_key "push_notifications", "users"
  add_foreign_key "reviews", "maps"
  add_foreign_key "reviews", "users"
end
