require 'test_helper'

class MapTest < ActiveSupport::TestCase
  test 'referenceable_by includes public maps, own maps and coauthored maps' do
    ids = Map.referenceable_by(users(:me)).pluck(:id)

    assert_includes ids, maps(:public_one).id              # own
    assert_includes ids, maps(:public_unfollowing).id      # public, someone else's
    assert_includes ids, maps(:private_following).id       # coauthored (me_on_private_following)
    assert_not_includes ids, maps(:private_unfollowing).id # someone else's private, not coauthor
  end

  test 'editable_by includes own and coauthored maps only' do
    ids = Map.editable_by(users(:me)).pluck(:id)

    assert_includes ids, maps(:public_one).id
    assert_includes ids, maps(:private_following).id
    assert_not_includes ids, maps(:public_unfollowing).id # public but not author/coauthor
  end

  test 'bookmarked_by returns only bookmarked maps' do
    ids = Map.bookmarked_by(users(:you)).pluck(:id)

    assert_includes ids, maps(:public_one).id # you_on_public_one
    assert_not_includes ids, maps(:public_two).id
  end

  test 'related_to combines authored, coauthored and bookmarked maps' do
    ids = Map.related_to(users(:me)).pluck(:id)

    assert_includes ids, maps(:public_one).id             # authored
    assert_includes ids, maps(:private_following).id      # coauthored
    assert_not_includes ids, maps(:public_unfollowing).id # not related
  end

  test 'related_to excludes a bookmarked map that is private' do
    map = maps(:public_one) # bookmarked by you (you_on_public_one)
    map.update_column(:private, true) # simulate a stale bookmark, bypassing the callback

    assert_not_includes Map.related_to(users(:you)).pluck(:id), map.id
  end

  test 'making a map private destroys its bookmarks' do
    map = maps(:public_one) # bookmarked by you (you_on_public_one)

    assert map.bookmarks.exists?

    map.update!(private: true)

    assert_not map.bookmarks.exists?
  end
end
