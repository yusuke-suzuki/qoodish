class AddBookmarkedToPushNotifications < ActiveRecord::Migration[7.2]
  def up
    add_column :push_notifications, :bookmarked, :boolean, default: false, null: false

    # Following a map became bookmarking it, so carry the retired followed
    # preference over to the setting that replaced it, the same way
    # coauthor_invited was seeded.
    execute 'UPDATE push_notifications SET bookmarked = followed'
  end

  def down
    remove_column :push_notifications, :bookmarked
  end
end
