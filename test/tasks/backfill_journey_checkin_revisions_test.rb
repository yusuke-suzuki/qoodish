require 'test_helper'

class BackfillJourneyCheckinRevisionsTest < ActiveSupport::TestCase
  TASK = Rails.root.join('lib/tasks/backfill_journey_checkin_revisions.rb').to_s

  test 'gives a checkin without a revision its first one' do
    checkin = detach_revision(journey_checkins(:my_finished_public_one))

    run_task

    revision = checkin.reload.current_revision

    assert_equal checkin.revisions.last, revision
    assert_equal checkin.note, revision.note
    assert_equal checkin.checked_in_at, revision.checked_in_at
    assert_predicate revision, :recorded?
  end

  test 'credits the revision to the owner of the journey' do
    checkin = detach_revision(journey_checkins(:my_finished_public_one))

    run_task

    assert_equal users(:me), checkin.reload.current_revision.user
  end

  test 'records the images the legacy imageable column holds' do
    checkin = detach_revision(journey_checkins(:my_finished_public_one))
    image = users(:me).owned_images.create!(
      imageable: checkin,
      url: 'https://imagedelivery.net/mockhash/checkin-backfill/public'
    )

    run_task

    assert_equal [image.id], checkin.reload.images.ids
  end

  test 'leaves the checkin last updated when it was' do
    checkin = detach_revision(journey_checkins(:my_finished_public_one))
    updated_at = checkin.updated_at

    run_task

    assert_equal updated_at, checkin.reload.updated_at
    assert_equal updated_at, checkin.current_revision.created_at
  end

  test 'a second run appends nothing' do
    detach_revision(journey_checkins(:my_finished_public_one))

    run_task

    assert_no_difference 'JourneyCheckinRevision.count' do
      run_task
    end
  end

  private

  def run_task
    capture_io { load TASK }
  end

  # The fixtures already carry a revision, so the state the backfill exists for
  # has to be restored first.
  def detach_revision(checkin)
    checkin.update_column(:current_revision_id, nil)
    checkin.revisions.destroy_all
    checkin
  end
end
