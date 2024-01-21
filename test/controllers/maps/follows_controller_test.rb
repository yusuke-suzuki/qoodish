require 'test_helper'

class Maps::FollowsControllerTest < ActionDispatch::IntegrationTest
  test 'follow public unfollowing map should be success' do
    stub_google_auth(users(:me)) do
      post "/maps/#{maps(:public_unfollowing).id}/follow",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal res['id'], maps(:public_unfollowing).id

    notification = Notification.where(notifiable: maps(:public_unfollowing),
                                      notifier: users(:me),
                                      recipient: maps(:public_unfollowing).user,
                                      key: 'followed').first

    assert_not_nil notification
  end
end
