require 'test_helper'

class JourneyCheckinTest < ActiveSupport::TestCase
  test 'checkin on an in-progress journey is created' do
    checkin = journeys(:my_in_progress).checkins.create!(pin: pins(:private_you))

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
    checkin = journeys(:my_finished).checkins.create!(
      pin: pins(:public_two),
      checked_in_at: '2026-06-01 11:00:00'
    )

    assert_predicate checkin, :persisted?
  end

  test 'checkins are ordered by visit time' do
    journey = journeys(:my_finished)
    retroactive = journey.checkins.create!(
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
end
