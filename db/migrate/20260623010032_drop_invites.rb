class DropInvites < ActiveRecord::Migration[7.2]
  def change
    drop_table :invites, force: :cascade do |t|
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
  end
end
