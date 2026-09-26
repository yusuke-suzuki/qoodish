require 'test_helper'

class MapVisibilityTest < ActiveSupport::TestCase
  test 'a removal hides a map from its own author' do
    map = maps(:private)

    assert_includes Map.referenceable_by(users(:me)), map

    decide(map, outcome: 'removed', reason: 'Spam map.')

    assert_not_includes Map.referenceable_by(users(:me)), map
  end

  test 'a removal hides a map the author can edit' do
    map = maps(:private)

    assert_includes Map.editable_by(users(:me)), map

    decide(map, outcome: 'removed', reason: 'Spam map.')

    assert_not_includes Map.editable_by(users(:me)), map
  end

  test 'a removal hides a map from the feed of someone related to it' do
    map = maps(:private)

    assert_includes Map.related_to(users(:me)), map

    decide(map, outcome: 'removed', reason: 'Spam map.')

    assert_not_includes Map.related_to(users(:me)), map
  end
end
