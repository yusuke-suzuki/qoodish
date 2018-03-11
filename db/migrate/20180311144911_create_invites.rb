class CreateInvites < ActiveRecord::Migration[5.1]
  def change
    create_table :invites do |t|
      t.references :invitable, polymorphic: true
      t.references :sender, polymorphic: true
      t.references :recipient, polymorphic: true
      t.boolean :expired, default: false
      t.timestamps
    end

    add_index :invites, %i[invitable_id invitable_type]
    add_index :invites, %i[sender_id sender_type]
    add_index :invites, %i[recipient_id recipient_type]
  end
end
