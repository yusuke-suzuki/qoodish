# rails runner lib/tasks/backfill_pin_revisions.rb
class BackfillPinRevisions
  def run
    Pin.where(current_revision_id: nil).find_each do |pin|
      image_ids = Image
                  .where(imageable_type: Pin.name, imageable_id: pin.id)
                  .order(:id)
                  .pluck(:id)

      revision = pin.revisions.create!(
        user_id: pin.user_id,
        status: pin.status,
        name: pin.name,
        comment: pin.comment,
        latitude: pin.latitude,
        longitude: pin.longitude,
        image_ids: image_ids,
        created_at: pin.updated_at,
        updated_at: pin.updated_at
      )

      pin.update_columns(current_revision_id: revision.id)

      puts "[Backfill] Pin #{pin.id}: revision #{revision.id} with #{image_ids.size} images"
    end
  end
end

runner = BackfillPinRevisions.new
runner.run
