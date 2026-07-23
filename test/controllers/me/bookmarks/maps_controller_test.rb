require 'test_helper'

class Me::Bookmarks::MapsControllerTest < ActionDispatch::IntegrationTest
  test 'index without authentication should raise unauthorized error' do
    get '/me/bookmarks/maps'

    assert_response :unauthorized
  end

  test 'index returns own bookmarked maps' do
    Bookmark.create!(map: maps(:public_unfollowing), user: users(:me))

    stub_google_auth(users(:me)) do
      get '/me/bookmarks/maps',
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    ids = JSON.parse(@response.body).map { |map| map['id'] }

    assert_equal [maps(:public_unfollowing).id], ids
  end

  test 'index does not return bookmarks of other users' do
    # Fixture you_on_public_one bookmarks public_one as :you; :me has none.
    stub_google_auth(users(:me)) do
      get '/me/bookmarks/maps',
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    assert_empty JSON.parse(@response.body)
  end
end
