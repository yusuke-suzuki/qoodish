class CreatePushNotifications < ActiveRecord::Migration[6.0]
  def change
    create_table :push_notifications do |t|
      t.references :user, index: true, foreign_key: true, null: false
      t.boolean :followed, default: false, null: false
      t.boolean :invited, default: false, null: false
      t.boolean :liked, default: false, null: false
      t.boolean :comment, default: false, null: false

      t.timestamps
    end
  end
end
