# rails runner lib/tasks/backfill_chapter_revisions.rb
class BackfillChapterRevisions
  def run
    Chapter.where(current_revision_id: nil).find_each { |chapter| backfill(chapter) }
  end

  private

  def backfill(chapter)
    Chapter.transaction do
      chapter.lock!

      next if chapter.current_revision_id

      image_ids = Image
                  .where(imageable_type: Chapter.name, imageable_id: chapter.id)
                  .order(:id)
                  .pluck(:id)

      revision = chapter.revisions.create!(
        user_id: chapter.user_id,
        status: chapter.status,
        title: chapter.title,
        content: chapter.content,
        map_features: chapter.map_features,
        image_ids: image_ids,
        created_at: chapter.updated_at,
        updated_at: chapter.updated_at
      )

      puts "[Backfill] Chapter #{chapter.id}: revision #{revision.id} with #{image_ids.size} images"
    end
  end
end

runner = BackfillChapterRevisions.new
runner.run
