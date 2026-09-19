require 'test_helper'

class MilestoneTest < ActiveSupport::TestCase
  test 'creation snapshots the pin name and coordinates' do
    pin = pins(:public_one)
    milestone = journeys(:my_unstarted).milestones.create!(pin: pin)

    assert_equal pin.name, milestone.name
    assert_equal pin.latitude, milestone.latitude
    assert_equal pin.longitude, milestone.longitude
  end

  test 'position is assigned in addition order' do
    journey = journeys(:my_in_progress)
    milestone = journey.milestones.create!(pin: pins(:private_you))

    assert_equal 2, milestone.position
  end

  test 'same pin cannot be added twice to a journey' do
    milestone = journeys(:my_in_progress).milestones.build(pin: pins(:private))

    assert_not milestone.valid?
  end

  test 'pin on another map cannot be added' do
    milestone = journeys(:my_unstarted).milestones.build(pin: pins(:private))

    assert_not milestone.valid?
  end

  test 'milestone cannot be added to a finished journey' do
    milestone = journeys(:my_finished).milestones.build(pin: pins(:public_two))

    assert_not milestone.valid?
  end

  test 'destroying the pin keeps the milestone with its snapshot' do
    milestone = milestones(:my_in_progress_first)

    milestone.pin.destroy!

    assert_nil milestone.reload.pin_id
    assert_equal 'This is a name', milestone.name
  end
end
