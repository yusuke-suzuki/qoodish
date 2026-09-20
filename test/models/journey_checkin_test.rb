require 'test_helper'

class JourneyCheckinTest < ActiveSupport::TestCase
  test 'checkin on an in-progress journey is created' do
    checkin = journeys(:my_in_progress).checkins.record!(user: users(:me), pin: pins(:private_you))

    assert_predicate checkin, :persisted?
  end

  test 'checkin on an unstarted journey is invalid' do
    checkin = journeys(:my_unstarted).checkins.build(pin: pins(:public_one))

    assert_not checkin.valid?
  end

  test 'checkin on a finished journey is invalid' do
    checkin = journeys(:my_finished).checkins.build(pin: pins(:public_two))

    assert_not checkin.valid?
  end

  test 'checkin on a finished journey with a visit time in the period is created' do
    checkin = journeys(:my_finished).checkins.record!(
      user: users(:me),
      pin: pins(:public_two),
      checked_in_at: '2026-06-01 11:00:00'
    )

    assert_predicate checkin, :persisted?
  end

  test 'checkins are ordered by visit time' do
    journey = journeys(:my_finished)
    retroactive = journey.checkins.record!(
      user: users(:me),
      pin: pins(:public_two),
      checked_in_at: '2026-06-01 10:15:00'
    )

    assert_equal retroactive.id, journey.checkins.reload.first.id
  end

  test 'same pin cannot be checked in twice on a journey' do
    checkin = journeys(:my_in_progress).checkins.build(pin: pins(:private))

    assert_not checkin.valid?
  end

  test 'pin on another map cannot be checked in' do
    checkin = journeys(:my_in_progress).checkins.build(pin: pins(:public_one))

    assert_not checkin.valid?
  end

  test 'record! writes the first revision and points the checkin at it' do
    checkin = JourneyCheckin.record!(
      user: users(:me),
      journey: journeys(:my_in_progress),
      pin: pins(:private_you),
      note: 'A short stop'
    )

    assert_equal 1, checkin.revisions.count
    assert_equal checkin.revisions.last, checkin.current_revision
    assert_predicate checkin, :recorded?
    assert_equal 'A short stop', checkin.current_revision.note
  end

  test 'a checkin cannot be created outside a revision' do
    checkin = journeys(:my_in_progress).checkins.build(pin: pins(:private_you))

    assert_not checkin.valid?
    assert_raises(ActiveRecord::RecordInvalid) { checkin.save! }
  end

  test 'the journey owner authors the revision of a checkin' do
    checkin = journeys(:my_in_progress).checkins.record!(
      user: users(:me),
      pin: pins(:private_you)
    )

    assert_equal users(:me), checkin.current_revision.user
    assert_equal checkin.user_id, checkin.current_revision.user_id
  end

  test 'revise! appends a revision and leaves the previous one untouched' do
    checkin = journey_checkins(:my_finished_public_one)
    previous = checkin.current_revision

    checkin.revise!(user: users(:me), note: 'Rewritten')

    assert_equal 'Rewritten', checkin.reload.note
    assert_equal 2, checkin.revisions.count
    assert_equal 'A fine spot', previous.reload.note
  end

  test 'a revision cannot be rewritten' do
    revision = journey_checkins(:my_finished_public_one).current_revision

    assert_raises(ActiveRecord::ReadonlyAttributeError) { revision.update!(note: 'rewritten') }
  end

  test 'content cannot be changed outside a revision' do
    checkin = journey_checkins(:my_finished_public_one)

    assert_raises(ActiveRecord::ReadOnlyRecord) { checkin.update!(note: 'Rewritten') }
    assert_equal 'A fine spot', checkin.reload.note
  end

  test 'discard! records the removal as a revision instead of dropping the row' do
    checkin = journey_checkins(:my_finished_public_one)

    assert_difference -> { checkin.revisions.count }, 1 do
      checkin.discard!(user: users(:me))
    end

    assert_predicate checkin.reload, :deleted?
    assert_predicate checkin.current_revision, :deleted?
    assert_not_includes journeys(:my_finished).checkins.reload, checkin
  end

  test 'discarding a checkin frees its pin to be checked in again' do
    checkin = journey_checkins(:my_in_progress_private)

    checkin.discard!(user: users(:me))

    assert_nil checkin.reload.pin_id

    checked_in_again = journeys(:my_in_progress).checkins.record!(
      user: users(:me),
      pin: pins(:private)
    )

    assert_predicate checked_in_again, :persisted?
    assert_not_equal checkin.id, checked_in_again.id
  end

  test 'a discarded checkin keeps the spot it snapshotted' do
    checkin = journey_checkins(:my_in_progress_private)

    checkin.discard!(user: users(:me))

    assert_equal 'This is a name', checkin.reload.name
    assert_in_delta 35.681382, checkin.lat
    assert_in_delta 139.766084, checkin.lng
  end

  test 'a journey can discard two checkins at the same pin' do
    journey = journeys(:my_in_progress)
    journey_checkins(:my_in_progress_private).discard!(user: users(:me))
    journey.checkins.record!(user: users(:me), pin: pins(:private)).discard!(user: users(:me))

    assert_empty journey.checkins.reload
    assert_equal 2, journey.all_checkins.count
  end

  test 'destroying the journey destroys the checkins it discarded' do
    journey = journeys(:my_in_progress)
    journey_checkins(:my_in_progress_private).discard!(user: users(:me))

    assert_difference 'JourneyCheckin.count', -1 do
      journey.destroy!
    end
  end
end
