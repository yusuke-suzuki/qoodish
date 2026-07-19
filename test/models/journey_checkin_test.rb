require 'test_helper'

class JourneyCheckinTest < ActiveSupport::TestCase
  test 'checkin on an in-progress journey is created' do
    checkin = journeys(:my_in_progress).checkins.create!(review: reviews(:private_you))

    assert_predicate checkin, :persisted?
  end

  test 'checkin on an unstarted journey is invalid' do
    checkin = journeys(:my_unstarted).checkins.build(review: reviews(:public_one))

    assert_not checkin.valid?
  end

  test 'checkin on a finished journey is invalid' do
    checkin = journeys(:my_finished).checkins.build(review: reviews(:public_two))

    assert_not checkin.valid?
  end

  test 'checkin on a finished journey with a visit time in the period is created' do
    checkin = journeys(:my_finished).checkins.create!(
      review: reviews(:public_two),
      checked_in_at: '2026-06-01 11:00:00'
    )

    assert_predicate checkin, :persisted?
  end

  test 'checkins are ordered by visit time' do
    journey = journeys(:my_finished)
    retroactive = journey.checkins.create!(
      review: reviews(:public_two),
      checked_in_at: '2026-06-01 11:00:00'
    )

    assert_equal retroactive.id, journey.checkins.reload.first.id
  end

  test 'same review cannot be checked in twice on a journey' do
    checkin = journeys(:my_in_progress).checkins.build(review: reviews(:private))

    assert_not checkin.valid?
  end

  test 'review on another map cannot be checked in' do
    checkin = journeys(:my_in_progress).checkins.build(review: reviews(:public_one))

    assert_not checkin.valid?
  end
end
