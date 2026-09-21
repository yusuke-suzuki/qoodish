require 'test_helper'

class BackfillJournalRevisionsTest < ActiveSupport::TestCase
  TASK = Rails.root.join('lib/tasks/backfill_journal_revisions.rb').to_s

  test 'gives a journal without a revision its first one' do
    journal = detach_revision(journals(:my_journal))

    run_task

    revision = journal.reload.current_revision

    assert_equal journal.revisions.last, revision
    assert_equal journal.title, revision.title
    assert_equal journal.description, revision.description
  end

  test 'credits the revision to the owner' do
    journal = detach_revision(journals(:you_journal))

    run_task

    assert_equal users(:you), journal.reload.current_revision.user
  end

  test 'leaves the journal last updated when it was' do
    journal = detach_revision(journals(:my_journal))
    updated_at = journal.updated_at

    run_task

    assert_equal updated_at, journal.reload.updated_at
    assert_equal updated_at, journal.current_revision.created_at
  end

  test 'a second run appends nothing' do
    detach_revision(journals(:my_journal))

    run_task

    assert_no_difference 'JournalRevision.count' do
      run_task
    end
  end

  private

  def run_task
    capture_io { load TASK }
  end

  # The fixtures already carry a revision, so the state the backfill exists for
  # has to be restored first.
  def detach_revision(journal)
    journal.update_column(:current_revision_id, nil)
    journal.revisions.destroy_all
    journal
  end
end
