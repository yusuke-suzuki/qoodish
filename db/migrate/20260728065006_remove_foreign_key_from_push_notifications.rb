class RemoveForeignKeyFromPushNotifications < ActiveRecord::Migration[7.2]
  def change
    remove_foreign_key :push_notifications, :users
  end
end
