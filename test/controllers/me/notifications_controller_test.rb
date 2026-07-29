require 'test_helper'

class Me::NotificationsControllerTest < ActionDispatch::IntegrationTest
  test 'index returns own notifications' do
    review = reviews(:public_one)
    Notification.create!(
      notifiable: review,
      notifier: users(:you),
      recipient: users(:me),
      key: 'liked'
    )

    stub_google_auth(users(:me)) do
      get '/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)
    notification = res.find { |n| n['notifiable']['id'] == review.id && n['notifiable']['type'] == 'review' }

    assert notification
    assert notification['notifiable'].key?('image')
  end

  test 'update marks the notification as read' do
    notification = Notification.create!(
      notifiable: reviews(:public_one),
      notifier: users(:you),
      recipient: users(:me),
      key: 'liked'
    )

    stub_google_auth(users(:me)) do
      put "/me/notifications/#{notification.id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert notification.reload.read
  end

  test 'update a notification with an orphaned notifier should raise not found error' do
    notification = Notification.create!(
      notifiable: reviews(:public_one),
      notifier: users(:you),
      recipient: users(:me),
      key: 'liked'
    )
    notification.update_columns(notifier_id: User.maximum(:id) + 1)

    stub_google_auth(users(:me)) do
      put "/me/notifications/#{notification.id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
    assert_not notification.reload.read
  end

  test 'update a notification of another user should raise not found error' do
    notification = Notification.create!(
      notifiable: reviews(:public_one),
      notifier: users(:me),
      recipient: users(:you),
      key: 'liked'
    )

    stub_google_auth(users(:me)) do
      put "/me/notifications/#{notification.id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end
end
