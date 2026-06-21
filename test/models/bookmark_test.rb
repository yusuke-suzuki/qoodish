require 'test_helper'

class BookmarkTest < ActiveSupport::TestCase
  test 'valid bookmark on a public map' do
    bookmark = Bookmark.new(map: maps(:public_two), user: users(:you))

    assert bookmark.valid?
  end

  test 'private map cannot be bookmarked' do
    bookmark = Bookmark.new(map: maps(:private), user: users(:you))

    assert_not bookmark.valid?
  end

  test 'same map cannot be bookmarked twice by the same user' do
    existing = bookmarks(:you_on_public_one)
    duplicate = Bookmark.new(map: existing.map, user: existing.user)

    assert_not duplicate.valid?
  end

  test 'author cannot bookmark own map' do
    bookmark = Bookmark.new(map: maps(:public_one), user: users(:me))

    assert_not bookmark.valid?
  end

  test 'coauthor cannot bookmark an editable map' do
    map = maps(:public_two)
    Coauthorship.create!(map: map, user: users(:you))
    bookmark = Bookmark.new(map: map, user: users(:you))

    assert_not bookmark.valid?
  end
end
