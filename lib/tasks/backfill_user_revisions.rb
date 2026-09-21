# rails runner lib/tasks/backfill_user_revisions.rb
class BackfillUserRevisions
  def run
    User.where(current_revision_id: nil).find_each { |user| backfill(user) }
  end

  private

  def backfill(user)
    User.transaction do
      user.lock!

      next if user.current_revision_id

      revision = user.revisions.create!(
        name: user.name,
        biography: user.biography,
        created_at: user.updated_at,
        updated_at: user.updated_at
      )

      puts "[Backfill] User #{user.id}: revision #{revision.id}"
    end
  end
end

runner = BackfillUserRevisions.new
runner.run
