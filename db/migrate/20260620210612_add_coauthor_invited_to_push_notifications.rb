class AddCoauthorInvitedToPushNotifications < ActiveRecord::Migration[7.2]
  def up
    # The dev database already has coauthor_invited from an earlier rename
    # migration that this PR removed, so skip when the column is present to
    # keep db:migrate runnable there as well as on a clean production database.
    return if column_exists?(:push_notifications, :coauthor_invited)

    add_column :push_notifications, :coauthor_invited, :boolean, default: false, null: false
    execute 'UPDATE push_notifications SET coauthor_invited = followed'
  end

  def down
    remove_column :push_notifications, :coauthor_invited
  end
end
