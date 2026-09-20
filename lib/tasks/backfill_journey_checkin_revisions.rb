# rails runner lib/tasks/backfill_journey_checkin_revisions.rb
class BackfillJourneyCheckinRevisions
  def run
    JourneyCheckin.where(current_revision_id: nil).find_each { |checkin| backfill(checkin) }
  end

  private

  def backfill(checkin)
    JourneyCheckin.transaction do
      checkin.lock!

      next if checkin.current_revision_id

      image_ids = Image
                  .where(imageable_type: JourneyCheckin.name, imageable_id: checkin.id)
                  .order(:id)
                  .pluck(:id)

      revision = checkin.revisions.create!(
        user_id: checkin.journey.user_id,
        status: checkin.status,
        note: checkin.note,
        checked_in_at: checkin.checked_in_at,
        image_ids: image_ids,
        created_at: checkin.updated_at,
        updated_at: checkin.updated_at
      )

      puts "[Backfill] JourneyCheckin #{checkin.id}: revision #{revision.id} with #{image_ids.size} images"
    end
  end
end

runner = BackfillJourneyCheckinRevisions.new
runner.run
