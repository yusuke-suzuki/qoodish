class MigrateLegacyNotificationKeys < ActiveRecord::Migration[7.2]
  # Old map invitations created notifications with key 'invited'. The coauthor
  # permission redesign replaced that flow with coauthorships and switched the
  # key to 'coauthor_invited', but existing notification rows kept the old key
  # and no longer resolve. Re-key them so they render as coauthor invitations.
  def up
    execute <<~SQL.squish
      UPDATE notifications SET key = 'coauthor_invited' WHERE key = 'invited'
    SQL
  end

  def down
    # Irreversible: after this runs, migrated 'invited' rows are
    # indistinguishable from notifications created as 'coauthor_invited'.
    raise ActiveRecord::IrreversibleMigration
  end
end
