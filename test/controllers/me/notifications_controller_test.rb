require 'test_helper'

class Me::NotificationsControllerTest < ActionDispatch::IntegrationTest
  test 'update marks the notification and the earlier ones of its group as read' do
    pin = pins(:public_one)
    earlier = Notification.create!(notifiable: pin, notifier: users(:me), recipient: users(:me), key: 'liked')
    notification = Notification.create!(notifiable: pin, notifier: users(:you), recipient: users(:me), key: 'liked')
    other_action = Notification.create!(notifiable: pin, notifier: users(:you), recipient: users(:me), key: 'comment')
    later = Notification.create!(notifiable: pin, notifier: users(:me), recipient: users(:me), key: 'liked')

    stub_google_auth(users(:me)) do
      put "/me/notifications/#{notification.id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert notification.reload.read
    assert earlier.reload.read
    assert_not other_action.reload.read
    assert_not later.reload.read
  end

  test 'update marks the notification as read' do
    notification = Notification.create!(
      notifiable: pins(:public_one),
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
      notifiable: pins(:public_one),
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
      notifiable: pins(:public_one),
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
