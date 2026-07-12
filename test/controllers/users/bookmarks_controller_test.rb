require 'test_helper'

class Users::BookmarksControllerTest < ActionDispatch::IntegrationTest
  test 'index without authentication should be unauthorized' do
    get "/users/#{users(:me).uid}/bookmarks"

    assert_response :unauthorized
  end

  test 'index returns own bookmarked maps' do
    Bookmark.create!(map: maps(:public_unfollowing), user: users(:me))

    stub_google_auth(users(:me)) do
      get "/users/#{users(:me).uid}/bookmarks",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    ids = JSON.parse(@response.body).map { |map| map['id'] }

    assert_equal [maps(:public_unfollowing).id], ids
  end

  test 'index returns another user bookmarked maps' do
    stub_google_auth(users(:me)) do
      get "/users/#{users(:you).id}/bookmarks",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    ids = JSON.parse(@response.body).map { |map| map['id'] }

    assert_includes ids, maps(:public_one).id
  end
end
