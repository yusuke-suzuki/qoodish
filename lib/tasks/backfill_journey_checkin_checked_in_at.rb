# bin/rails runner lib/tasks/backfill_journey_checkin_checked_in_at.rb
#
# Populates checked_in_at added by 20260719172202_add_checked_in_at_to_journey_checkins.
# Rows created before the column existed treat creation time as the visit time,
# so created_at is copied verbatim.
# Run between that migration and 20260720102542_change_journey_checkins_checked_in_at_null,
# which assumes no NULL rows remain.

updated = JourneyCheckin.where(checked_in_at: nil).update_all('checked_in_at = created_at')
Rails.logger.info("Backfill complete: #{updated} journey checkins")
