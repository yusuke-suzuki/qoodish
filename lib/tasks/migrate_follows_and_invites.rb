# bin/rails runner lib/tasks/migrate_follows_and_invites.rb
#
# Splits the polymorphic follows/invites into coauthorships, bookmarks and
# coauthorship_invitations while preserving each follower's existing ability:
#   - followers of shared maps         -> coauthors (keep edit ability)
#   - followers of public non-shared   -> bookmarks (keep read/subscribe)
#   - followers of private non-shared  -> dropped (private is now author/coauthor only)
# Author self-follows are dropped (the author is maps.user_id).
#
# Run after the additive migrations and while follows/invites still exist (i.e.
# before the follow-up migration that drops them). Idempotent: re-running it
# before cutover picks up rows the old API created in the meantime without
# duplicating anything (INSERT IGNORE + the pending-invitation guard). When the
# legacy tables are already gone (e.g. an environment that ran an earlier
# migration which dropped them), the matching section is skipped instead of
# failing, so the script is safe to run anywhere.

connection = ActiveRecord::Base.connection

if connection.table_exists?(:follows)
  coauthor_source = connection.select_value(<<~SQL.squish)
    SELECT COUNT(*)
    FROM follows f
    JOIN maps m ON m.id = f.followable_id
    WHERE f.followable_type = 'Map'
      AND f.follower_type = 'User'
      AND m.shared = TRUE
      AND f.follower_id <> m.user_id
  SQL

  bookmark_source = connection.select_value(<<~SQL.squish)
    SELECT COUNT(*)
    FROM follows f
    JOIN maps m ON m.id = f.followable_id
    WHERE f.followable_type = 'Map'
      AND f.follower_type = 'User'
      AND m.shared = FALSE
      AND m.private = FALSE
      AND f.follower_id <> m.user_id
  SQL

  access_lost = connection.select_value(<<~SQL.squish)
    SELECT COUNT(*)
    FROM follows f
    JOIN maps m ON m.id = f.followable_id
    WHERE f.followable_type = 'Map'
      AND f.follower_type = 'User'
      AND m.shared = FALSE
      AND m.private = TRUE
      AND f.follower_id <> m.user_id
  SQL

  Rails.logger.info(
    "Follows migration: #{coauthor_source} coauthors, #{bookmark_source} bookmarks, " \
    "#{access_lost} losing access (private non-shared)"
  )

  connection.execute(<<~SQL.squish)
    INSERT IGNORE INTO coauthorships (map_id, user_id, created_at, updated_at)
    SELECT f.followable_id, f.follower_id, f.created_at, f.updated_at
    FROM follows f
    JOIN maps m ON m.id = f.followable_id
    WHERE f.followable_type = 'Map'
      AND f.follower_type = 'User'
      AND m.shared = TRUE
      AND f.follower_id <> m.user_id
  SQL

  connection.execute(<<~SQL.squish)
    INSERT IGNORE INTO bookmarks (map_id, user_id, created_at, updated_at)
    SELECT f.followable_id, f.follower_id, f.created_at, f.updated_at
    FROM follows f
    JOIN maps m ON m.id = f.followable_id
    WHERE f.followable_type = 'Map'
      AND f.follower_type = 'User'
      AND m.shared = FALSE
      AND m.private = FALSE
      AND f.follower_id <> m.user_id
  SQL
else
  Rails.logger.info('Follows table is gone; skipping coauthorship/bookmark backfill (already migrated)')
end

if connection.table_exists?(:invites)
  invitation_source = connection.select_value(<<~SQL.squish)
    SELECT COUNT(*)
    FROM invites i
    JOIN maps m ON m.id = i.invitable_id
    WHERE i.invitable_type = 'Map'
      AND i.sender_type = 'User'
      AND i.recipient_type = 'User'
      AND i.expired = FALSE
      AND i.recipient_id <> m.user_id
  SQL

  Rails.logger.info("Invites migration: #{invitation_source} pending invitations")

  connection.execute(<<~SQL.squish)
    INSERT INTO coauthorship_invitations
      (map_id, inviter_id, invitee_id, status, created_at, updated_at)
    SELECT i.invitable_id, i.sender_id, i.recipient_id, 0, i.created_at, i.updated_at
    FROM invites i
    JOIN maps m ON m.id = i.invitable_id
    WHERE i.invitable_type = 'Map'
      AND i.sender_type = 'User'
      AND i.recipient_type = 'User'
      AND i.expired = FALSE
      AND i.recipient_id <> m.user_id
      AND NOT EXISTS (
        SELECT 1 FROM coauthorship_invitations ci
        WHERE ci.map_id = i.invitable_id
          AND ci.invitee_id = i.recipient_id
          AND ci.status = 0
      )
  SQL
else
  Rails.logger.info('Invites table is gone; skipping invitation backfill (already migrated)')
end

Rails.logger.info(
  "Follows/invites migration complete: " \
  "#{Coauthorship.count} coauthorships, #{Bookmark.count} bookmarks, " \
  "#{CoauthorshipInvitation.count} coauthorship invitations now exist"
)
