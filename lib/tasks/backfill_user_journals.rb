# bin/rails runner lib/tasks/backfill_user_journals.rb
#
# Creates the default journal for users that existed before journals
# were introduced, mirroring what User#create_default_journal does on
# signup.
# Safe to re-run: users that already have a journal are skipped.

created = 0

User.where.missing(:journal).find_each do |user|
  user.create_journal!(title: "#{user.name}'s journal".truncate(50))
  created += 1
end

Rails.logger.info("Backfill complete: #{created} journals")
