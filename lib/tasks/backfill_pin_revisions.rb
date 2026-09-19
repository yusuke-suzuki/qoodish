# rails runner lib/tasks/backfill_pin_revisions.rb
class BackfillPinRevisions
  # An image this misses is absent from the revision for good, and the pin is
  # skipped from then on, so both names are accepted rather than relying on
  # rename_review_polymorphic_types.rb having run first.
  IMAGEABLE_TYPES = %w[Review Pin].freeze

  def run
    Pin.where(current_revision_id: nil).find_each { |pin| backfill(pin) }
  end

  private

  def backfill(pin)
    Pin.transaction do
      pin.lock!

      next if pin.current_revision_id

      image_ids = Image
                  .where(imageable_type: IMAGEABLE_TYPES, imageable_id: pin.id)
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
