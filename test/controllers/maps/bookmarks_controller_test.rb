require 'test_helper'

class Maps::BookmarksControllerTest < ActionDispatch::IntegrationTest
  test 'bookmark a public map should be success' do
    assert_difference 'Bookmark.count', 1 do
      stub_google_auth(users(:me)) do
        post "/maps/#{maps(:public_unfollowing).id}/bookmark",
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal res['id'], maps(:public_unfollowing).id
  end

  test 'bookmarking a public map does not create a notification' do
    assert_no_difference 'Notification.count' do
      stub_google_auth(users(:me)) do
        post "/maps/#{maps(:public_unfollowing).id}/bookmark",
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end
  end

  test 'bookmark a private map should raise not found error' do
    stub_google_auth(users(:me)) do
      post "/maps/#{maps(:private_unfollowing).id}/bookmark",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'bookmark own public map should be forbidden' do
    stub_google_auth(users(:me)) do
      post "/maps/#{maps(:public_one).id}/bookmark",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :forbidden
  end

  test 'unbookmark a bookmarked map should be success' do
    Bookmark.create!(map: maps(:public_unfollowing), user: users(:me))

    assert_difference 'Bookmark.count', -1 do
      stub_google_auth(users(:me)) do
        delete "/maps/#{maps(:public_unfollowing).id}/bookmark",
               headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
  end
end
