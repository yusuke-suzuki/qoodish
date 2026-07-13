require 'test_helper'

class MilestoneTest < ActiveSupport::TestCase
  test 'creation snapshots the review name and coordinates' do
    review = reviews(:public_one)
    milestone = journeys(:my_unstarted).milestones.create!(review: review)

    assert_equal review.name, milestone.name
    assert_equal review.latitude, milestone.latitude
    assert_equal review.longitude, milestone.longitude
  end

  test 'position is assigned in addition order' do
    journey = journeys(:my_in_progress)
    milestone = journey.milestones.create!(review: reviews(:private_you))

    assert_equal 2, milestone.position
  end

  test 'same review cannot be added twice to a journey' do
    milestone = journeys(:my_in_progress).milestones.build(review: reviews(:private))

    assert_not milestone.valid?
  end

  test 'review on another map cannot be added' do
    milestone = journeys(:my_unstarted).milestones.build(review: reviews(:private))

    assert_not milestone.valid?
  end

  test 'milestone cannot be added to a finished journey' do
    milestone = journeys(:my_finished).milestones.build(review: reviews(:public_two))

    assert_not milestone.valid?
  end

  test 'destroying the review keeps the milestone with its snapshot' do
    milestone = milestones(:my_in_progress_first)

    milestone.review.destroy!

    assert_nil milestone.reload.review_id
    assert_equal 'This is a name', milestone.name
  end
end
