require 'test_helper'

class BackfillUserRevisionsTest < ActiveSupport::TestCase
  TASK = Rails.root.join('lib/tasks/backfill_user_revisions.rb').to_s

  test 'gives an account without a revision its first one' do
    user = detach_revision(users(:me))

    run_task

    revision = user.reload.current_revision

    assert_equal user.revisions.last, revision
    assert_equal user.name, revision.name
    assert_equal user.biography, revision.biography
  end

  test 'leaves the account last updated when it was' do
    user = detach_revision(users(:me))
    updated_at = user.updated_at

    run_task

    assert_equal updated_at, user.reload.updated_at
    assert_equal updated_at, user.current_revision.created_at
  end

  test 'a second run appends nothing' do
    detach_revision(users(:me))

    run_task

    assert_no_difference 'UserRevision.count' do
      run_task
    end
  end

  private

  def run_task
    capture_io { load TASK }
  end

  # The fixtures already carry a revision, so the state the backfill exists for
  # has to be restored first.
  def detach_revision(user)
    user.update_column(:current_revision_id, nil)
    user.revisions.destroy_all
    user
  end
end
