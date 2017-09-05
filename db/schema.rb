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

ActiveRecord::Schema.define(version: 20170901041457) do

  create_table "devices", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "registration_token", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["registration_token"], name: "index_devices_on_registration_token"
    t.index ["user_id", "registration_token"], name: "index_devices_on_user_id_and_registration_token", unique: true
    t.index ["user_id"], name: "index_devices_on_user_id"
  end

  create_table "follows", force: :cascade do |t|
    t.string "followable_type", null: false
    t.integer "followable_id", null: false
    t.string "follower_type", null: false
    t.integer "follower_id", null: false
    t.boolean "blocked", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["followable_id", "followable_type"], name: "fk_followables"
    t.index ["followable_type", "followable_id"], name: "index_follows_on_followable_type_and_followable_id"
    t.index ["follower_id", "follower_type"], name: "fk_follows"
    t.index ["follower_type", "follower_id"], name: "index_follows_on_follower_type_and_follower_id"
  end

  create_table "inappropriate_contents", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "content_id_val", null: false
    t.string "content_type", null: false
    t.integer "reason_id_val", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_inappropriate_contents_on_user_id"
  end

  create_table "maps", force: :cascade do |t|
    t.integer "user_id", null: false
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

  create_table "reviews", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "map_id", null: false
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

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "uid", null: false
    t.string "provider", null: false
    t.string "provider_uid", null: false
    t.string "provider_token"
    t.string "image_path"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "provider_uid"], name: "index_users_on_provider_and_provider_uid", unique: true
    t.index ["uid"], name: "index_users_on_uid"
  end

end
