# rails runner lib/tasks/backfill_journal_revisions.rb
class BackfillJournalRevisions
  def run
    Journal.where(current_revision_id: nil).find_each { |journal| backfill(journal) }
  end

  private

  def backfill(journal)
    Journal.transaction do
      journal.lock!

      next if journal.current_revision_id

      revision = journal.revisions.create!(
        user_id: journal.user_id,
        title: journal.title,
        description: journal.description,
        created_at: journal.updated_at,
        updated_at: journal.updated_at
      )

      puts "[Backfill] Journal #{journal.id}: revision #{revision.id}"
    end
  end
end

runner = BackfillJournalRevisions.new
runner.run
