require 'test_helper'

class JourneyTest < ActiveSupport::TestCase
  test 'valid journey on a referenceable map' do
    journey = Journey.new(user: users(:you), map: maps(:public_two))

    assert journey.valid?
  end

  test 'second unfinished journey on the same map is invalid' do
    journey = Journey.new(user: users(:me), map: maps(:public_one))

    assert_not journey.valid?
  end

  test 'new journey is allowed on a map with only finished journeys' do
    journeys(:my_unstarted).destroy!

    journey = Journey.new(user: users(:me), map: maps(:public_one))

    assert journey.valid?
  end

  test 'start! stamps started_at' do
    journey = journeys(:my_unstarted)

    journey.start!

    assert_predicate journey, :in_progress?
  end

  test 'start! on a started journey raises a conflict' do
    assert_raises Exceptions::Conflict do
      journeys(:my_in_progress).start!
    end
  end

  test 'finish! stamps finished_at' do
    journey = journeys(:my_in_progress)

    journey.finish!

    assert_predicate journey, :finished?
  end

  test 'finish! stores the encoded path submitted with it' do
    journey = journeys(:my_in_progress)

    journey.finish!(encoded_path: 'a~l~Fjk~uOwHJy@P')

    assert_predicate journey, :finished?
    assert_equal 'a~l~Fjk~uOwHJy@P', journey.encoded_path
  end

  test 'finish! on an unstarted journey raises a conflict' do
    assert_raises Exceptions::Conflict do
      journeys(:my_unstarted).finish!
    end
  end

  test 'destroying the map keeps the journey without a map' do
    journey = journeys(:my_in_progress)

    journey.map.destroy!

    assert_nil journey.reload.map_id
  end

  test 'destroying a journey nullifies the chapter reference' do
    chapter = chapters(:my_draft)

    chapter.journey.destroy!

    assert_nil chapter.reload.journey_id
  end
end
