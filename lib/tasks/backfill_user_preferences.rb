# bin/rails runner lib/tasks/backfill_user_preferences.rb
#
# Carries the explicit choices stored in push_notifications into
# user_preferences as one full snapshot per user. Reads fall through
# to push_notifications until this has run, so there is no urgency;
# run it any time before the release that removes that fallback and
# drops the table.
# Safe to re-run: users that already have a snapshot are skipped.

backfilled = 0

PushNotification.includes(:user).find_each do |row|
  next if row.user.preferences.exists?

  row.user.preferences.create!(
    web_push: {
      'coauthor_invited' => row.coauthor_invited,
      'liked' => row.liked,
      'comment' => row.comment
    }
  )
  backfilled += 1
end

Rails.logger.info("Backfill complete: #{backfilled} snapshots")
