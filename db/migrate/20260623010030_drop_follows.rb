class DropFollows < ActiveRecord::Migration[7.2]
  def change
    drop_table :follows, force: :cascade do |t|
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
  end
end
