require 'test_helper'

class Me::NotificationsControllerTest < ActionDispatch::IntegrationTest
  test 'index returns own notifications' do
    pin = pins(:public_one)
    Notification.create!(
      notifiable: pin,
      notifier: users(:you),
      recipient: users(:me),
      key: 'liked'
    )

    stub_google_auth(users(:me)) do
      get '/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)
    notification = res.find { |n| n['notifiable']['id'] == pin.id && n['notifiable']['type'] == 'review' }

    assert notification
    assert notification['notifiable'].key?('image')
  end

  test 'index serves the image of a liked comment from its pin' do
    comment = comments(:one)
    Notification.create!(notifiable: comment, notifier: users(:you), recipient: users(:me), key: 'liked')
    Notification.create!(notifiable: pins(:public_two), notifier: users(:you), recipient: users(:me), key: 'liked')

    stub_google_auth(users(:me)) do
      get '/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    notification = JSON.parse(@response.body).find { |n| n['notifiable']['type'] == 'comment' }

    assert_equal comment.commentable.image_variants.as_json, notification['notifiable']['image']
  end

  test 'index drops a notification whose pin is deleted' do
    pin = pins(:public_one)
    [pin, pins(:public_two)].each do |notifiable|
      Notification.create!(
        notifiable: notifiable,
        notifier: users(:you),
        recipient: users(:me),
        key: 'liked'
      )
    end
    pin.discard!(user: users(:me))

    stub_google_auth(users(:me)) do
      get '/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_empty res.select { |n| n['notifiable']['id'] == pin.id }
    assert_not_empty res.select { |n| n['notifiable']['id'] == pins(:public_two).id }
  end

  test 'index groups notifications of the same action on the same subject' do
    pin = pins(:public_one)
    Notification.create!(notifiable: pin, notifier: users(:me), recipient: users(:me), key: 'liked', read: true)
    latest = Notification.create!(notifiable: pin, notifier: users(:you), recipient: users(:me), key: 'liked')

    stub_google_auth(users(:me)) do
      get '/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    groups = JSON.parse(@response.body).select { |n| n['notifiable']['id'] == pin.id }

    assert_equal 1, groups.size
    assert_equal latest.id, groups.first['id']
    assert_equal 2, groups.first['notifiers_count']
    assert_equal [users(:you).id, users(:me).id], groups.first['notifiers'].pluck('id')
    assert_equal users(:you).id, groups.first['notifier']['id']
    assert_not groups.first['read']
  end

  test 'index counts a notifier repeating an action once' do
    pin = pins(:public_one)
    2.times { Notification.create!(notifiable: pin, notifier: users(:you), recipient: users(:me), key: 'comment') }

    stub_google_auth(users(:me)) do
      get '/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    group = JSON.parse(@response.body).find { |n| n['notifiable']['id'] == pin.id }

    assert_equal 1, group['notifiers_count']
    assert_equal [users(:you).id], group['notifiers'].pluck('id')
  end

  test 'index keeps different actions on the same subject apart' do
    pin = pins(:public_one)
    %w[liked comment].each do |key|
      Notification.create!(notifiable: pin, notifier: users(:you), recipient: users(:me), key: key)
    end

    stub_google_auth(users(:me)) do
      get '/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    groups = JSON.parse(@response.body).select { |n| n['notifiable']['id'] == pin.id }

    assert_equal %w[comment liked], groups.pluck('key')
  end

  test 'index reads a group as read once all of it is read' do
    pin = pins(:public_one)
    2.times { Notification.create!(notifiable: pin, notifier: users(:you), recipient: users(:me), key: 'liked', read: true) }

    stub_google_auth(users(:me)) do
      get '/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert JSON.parse(@response.body).find { |n| n['notifiable']['id'] == pin.id }['read']
  end

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
