require 'test_helper'

class Chapters::LikesControllerTest < ActionDispatch::IntegrationTest
  test 'like a published chapter should create a vote and a notification' do
    chapter = chapters(:you_published)

    assert_difference ['Vote.count', 'Notification.count'], 1 do
      stub_google_auth(users(:me)) do
        post "/chapters/#{chapter.id}/like",
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert res['liked']
    assert_equal 1, res['likes_count']

    notification = Notification.last

    assert_equal chapter, notification.notifiable
    assert_equal users(:me), notification.notifier
    assert_equal users(:you), notification.recipient
    assert_equal 'liked', notification.key
  end

  test 'liking a chapter twice is idempotent' do
    chapter = chapters(:you_published)

    stub_google_auth(users(:me)) do
      post "/chapters/#{chapter.id}/like",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    assert_no_difference ['Vote.count', 'Notification.count'] do
      stub_google_auth(users(:me)) do
        post "/chapters/#{chapter.id}/like",
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert res['liked']
    assert_equal 1, res['likes_count']
  end

  test 'like a published chapter on a private map as a coauthor should be success' do
    stub_google_auth(users(:me)) do
      post "/chapters/#{chapters(:you_private_published_following).id}/like",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
  end

  test 'like a draft chapter should raise not found error' do
    stub_google_auth(users(:you)) do
      post "/chapters/#{chapters(:my_draft).id}/like",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'like a chapter on an unreferenceable private map should raise not found error' do
    stub_google_auth(users(:me)) do
      post "/chapters/#{chapters(:you_private_published_unfollowing).id}/like",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'unlike a chapter should destroy the vote' do
    chapter = chapters(:my_published)

    assert_difference 'Vote.count', -1 do
      stub_google_auth(users(:you)) do
        delete "/chapters/#{chapter.id}/like",
               headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not res['liked']
    assert_equal 0, res['likes_count']
  end

  test 'unlike a chapter without an existing like should raise not found error' do
    stub_google_auth(users(:me)) do
      delete "/chapters/#{chapters(:you_published).id}/like",
             headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'like a chapter without authentication should raise unauthorized error' do
    post "/chapters/#{chapters(:you_published).id}/like"

    assert_response :unauthorized
  end
end
