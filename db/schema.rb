# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2018_08_06_062008) do

  create_table "devices", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "registration_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["registration_token"], name: "index_devices_on_registration_token"
    t.index ["user_id", "registration_token"], name: "index_devices_on_user_id_and_registration_token", unique: true
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "follows", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "followable_type", null: false
    t.bigint "followable_id", null: false
    t.string "follower_type", null: false
    t.bigint "follower_id", null: false
    t.boolean "blocked", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followable_id", "followable_type"], name: "fk_followables"
    t.index ["followable_type", "followable_id"], name: "index_follows_on_followable_type_and_followable_id"
    t.index ["follower_id", "follower_type"], name: "fk_follows"
    t.index ["follower_type", "follower_id"], name: "index_follows_on_follower_type_and_follower_id"
  end

  create_table "inappropriate_contents", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "content_id_val", null: false
    t.string "content_type", null: false
    t.integer "reason_id_val", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_inappropriate_contents_on_user_id"
  end

  create_table "invites", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "invitable_type"
    t.bigint "invitable_id"
    t.string "sender_type"
    t.bigint "sender_id"
    t.string "recipient_type"
    t.bigint "recipient_id"
    t.boolean "expired", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["invitable_id", "invitable_type"], name: "index_invites_on_invitable_id_and_invitable_type"
    t.index ["invitable_type", "invitable_id"], name: "index_invites_on_invitable_type_and_invitable_id"
    t.index ["recipient_id", "recipient_type"], name: "index_invites_on_recipient_id_and_recipient_type"
    t.index ["recipient_type", "recipient_id"], name: "index_invites_on_recipient_type_and_recipient_id"
    t.index ["sender_id", "sender_type"], name: "index_invites_on_sender_id_and_sender_type"
    t.index ["sender_type", "sender_id"], name: "index_invites_on_sender_type_and_sender_id"
  end

  create_table "maps", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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
    t.index ["user_id"], name: "index_maps_on_user_id"
  end

  create_table "notifications", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  create_table "reviews", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "map_id", null: false
    t.string "place_id_val", null: false
    t.string "comment", null: false
    t.string "image_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["map_id"], name: "index_reviews_on_map_id"
    t.index ["place_id_val", "map_id", "user_id"], name: "index_reviews_on_place_id_val_and_map_id_and_user_id", unique: true
    t.index ["place_id_val"], name: "index_reviews_on_place_id_val"
    t.index ["user_id"], name: "index_reviews_on_user_id"
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "uid", null: false
    t.string "image_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["image_path"], name: "index_users_on_image_path", unique: true
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  create_table "votes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
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

  add_foreign_key "devices", "users"
  add_foreign_key "maps", "users"
  add_foreign_key "reviews", "maps"
  add_foreign_key "reviews", "users"
end
