require 'test_helper'

class BackfillCommentRevisionsTest < ActiveSupport::TestCase
  TASK = Rails.root.join('lib/tasks/backfill_comment_revisions.rb').to_s

  test 'gives a comment without a revision its first one' do
    comment = detach_revision(comments(:one))

    run_task

    revision = comment.reload.current_revision

    assert_equal comment.revisions.last, revision
    assert_equal comment.body, revision.body
    assert_predicate revision, :published?
  end

  test 'credits the revision to the author' do
    comment = detach_revision(comments(:two))

    run_task

    assert_equal users(:you), comment.reload.current_revision.user
  end

  test 'records the deleted status a comment still holds' do
    comment = detach_revision(comments(:one))
    comment.update_column(:status, 'deleted')

    run_task

    assert_predicate comment.reload.current_revision, :deleted?
  end

  test 'leaves the comment last updated when it was' do
    comment = detach_revision(comments(:one))
    updated_at = comment.updated_at

    run_task

    assert_equal updated_at, comment.reload.updated_at
    assert_equal updated_at, comment.current_revision.created_at
  end

  test 'a second run appends nothing' do
    detach_revision(comments(:one))

    run_task

    assert_no_difference 'CommentRevision.count' do
      run_task
    end
  end

  private

  def run_task
    capture_io { load TASK }
  end

  # The fixtures already carry a revision, so the state the backfill exists for
  # has to be restored first.
  def detach_revision(comment)
    comment.update_column(:current_revision_id, nil)
    comment.revisions.destroy_all
    comment
  end
end
