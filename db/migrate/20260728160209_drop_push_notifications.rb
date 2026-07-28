class DropPushNotifications < ActiveRecord::Migration[7.2]
  def change
    drop_table :push_notifications do |t|
      t.bigint :user_id, null: false
      t.boolean :followed, default: false, null: false
      t.boolean :invited, default: false, null: false
      t.boolean :liked, default: false, null: false
      t.boolean :comment, default: false, null: false
      t.timestamps
      t.boolean :coauthor_invited, default: false, null: false

      t.index :user_id
    end
  end
end
