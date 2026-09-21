# rails runner lib/tasks/backfill_comment_revisions.rb
class BackfillCommentRevisions
  def run
    Comment.where(current_revision_id: nil).find_each { |comment| backfill(comment) }
  end

  private

  def backfill(comment)
    Comment.transaction do
      comment.lock!

      next if comment.current_revision_id

      revision = comment.revisions.create!(
        user_id: comment.user_id,
        status: comment.status,
        body: comment.body,
        created_at: comment.updated_at,
        updated_at: comment.updated_at
      )

      puts "[Backfill] Comment #{comment.id}: revision #{revision.id}"
    end
  end
end

runner = BackfillCommentRevisions.new
runner.run
