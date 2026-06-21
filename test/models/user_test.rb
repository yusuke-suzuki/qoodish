require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test 'map_author? is true only for own maps' do
    assert users(:me).map_author?(maps(:public_one))
    assert_not users(:me).map_author?(maps(:public_unfollowing))
  end

  test 'editable? is true for author and coauthor' do
    assert users(:me).editable?(maps(:public_one))        # author
    assert users(:me).editable?(maps(:private_following)) # coauthor
    assert_not users(:me).editable?(maps(:public_unfollowing))
  end

  test 'bookmarkable? is true only for public maps the user is not involved with' do
    assert users(:me).bookmarkable?(maps(:public_unfollowing))      # public, not involved
    assert_not users(:me).bookmarkable?(maps(:public_one))          # author
    assert_not users(:me).bookmarkable?(maps(:private_unfollowing)) # private
    assert_not users(:me).bookmarkable?(maps(:private_following))   # coauthor
  end
end
