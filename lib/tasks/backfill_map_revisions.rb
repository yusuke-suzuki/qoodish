# rails runner lib/tasks/backfill_map_revisions.rb
class BackfillMapRevisions
  def run
    Map.where(current_revision_id: nil).find_each { |map| backfill(map) }
  end

  private

  def backfill(map)
    Map.transaction do
      map.lock!

      next if map.current_revision_id

      # maps.private is nullable and a revision has to say what it recorded.
      # An unset visibility means the column default, which is private.
      map.update_column(:private, true) if map.private.nil?

      image_ids = Image
                  .where(imageable_type: Map.name, imageable_id: map.id)
                  .order(:id)
                  .pluck(:id)

      revision = map.revisions.create!(
        user_id: map.user_id,
        status: map.status,
        name: map.name,
        description: map.description,
        latitude: map.latitude,
        longitude: map.longitude,
        private: map.private,
        image_ids: image_ids,
        created_at: map.updated_at,
        updated_at: map.updated_at
      )

      puts "[Backfill] Map #{map.id}: revision #{revision.id} with #{image_ids.size} images"
    end
  end
end

runner = BackfillMapRevisions.new
runner.run
