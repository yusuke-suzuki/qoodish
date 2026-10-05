require 'test_helper'

class V2::Me::NotificationsControllerTest < ActionDispatch::IntegrationTest
  test 'index pages through the groups with the cursor it hands out' do
    subjects = Pin.published.to_a.product(%w[liked comment]).first(NotificationGroup::PER_PAGE + 1)
    created = subjects.map do |pin, key|
      Notification.create!(notifiable: pin, notifier: users(:you), recipient: users(:me), key: key)
    end

    stub_google_auth(users(:me)) do
      get '/v2/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    first_page = JSON.parse(@response.body)

    assert_equal NotificationGroup::PER_PAGE, first_page['data'].size
    assert_kind_of String, first_page['next_cursor']

    stub_google_auth(users(:me)) do
      get '/v2/me/notifications',
          params: { cursor: first_page['next_cursor'] },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    last_page = JSON.parse(@response.body)

    assert_equal [created.first.id], last_page['data'].pluck('id')
    assert_nil last_page['next_cursor']
  end

  test 'index narrows to the groups that hold something unread' do
    Notification.create!(notifiable: pins(:public_one), notifier: users(:you), recipient: users(:me), key: 'liked', read: true)
    unread = Notification.create!(notifiable: pins(:public_one), notifier: users(:you), recipient: users(:me), key: 'comment')
    Notification.create!(notifiable: pins(:public_two), notifier: users(:you), recipient: users(:me), key: 'liked', read: true)

    stub_google_auth(users(:me)) do
      get '/v2/me/notifications', params: { read: false }, headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert_equal [unread.id], JSON.parse(@response.body)['data'].pluck('id')
  end

  test 'index groups notifications of the same action on the same subject' do
    pin = pins(:public_one)
    Notification.create!(notifiable: pin, notifier: users(:me), recipient: users(:me), key: 'liked', read: true)
    latest = Notification.create!(notifiable: pin, notifier: users(:you), recipient: users(:me), key: 'liked')

    stub_google_auth(users(:me)) do
      get '/v2/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    groups = JSON.parse(@response.body)['data'].select { |n| n['notifiable']['id'] == pin.id }

    assert_equal 1, groups.size
    assert_equal latest.id, groups.first['id']
    assert_equal 'pin', groups.first['notifiable']['type']
    assert_equal 2, groups.first['notifiers_count']
    assert_equal [users(:you).id, users(:me).id], groups.first['notifiers'].pluck('id')
    assert_equal users(:you).id, groups.first['notifier']['id']
    assert_not groups.first['read']
  end

  test 'index serves groups of every kind of subject without N+1 queries' do
    [comments(:one), comments(:two), pins(:public_one), pins(:public_two), chapters(:my_published)].each do |notifiable|
      %i[me you].each do |notifier|
        Notification.create!(notifiable: notifiable, notifier: users(notifier), recipient: users(:me), key: 'liked')
      end
    end

    stub_google_auth(users(:me)) do
      get '/v2/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    comment = JSON.parse(@response.body)['data'].find { |n| n['notifiable']['type'] == 'comment' }

    assert_equal pins(:public_one).image_variants.as_json, comment['notifiable']['image']
  end

  test 'index drops a notification whose pin is deleted' do
    pin = pins(:public_one)
    [pin, pins(:public_two)].each do |notifiable|
      Notification.create!(notifiable: notifiable, notifier: users(:you), recipient: users(:me), key: 'liked')
    end
    pin.discard!(user: users(:me))

    stub_google_auth(users(:me)) do
      get '/v2/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    data = JSON.parse(@response.body)['data']

    assert_empty data.select { |n| n['notifiable']['id'] == pin.id }
    assert_not_empty data.select { |n| n['notifiable']['id'] == pins(:public_two).id }
  end

  test 'index counts a notifier repeating an action once' do
    pin = pins(:public_one)
    2.times { Notification.create!(notifiable: pin, notifier: users(:you), recipient: users(:me), key: 'comment') }

    stub_google_auth(users(:me)) do
      get '/v2/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    group = JSON.parse(@response.body)['data'].find { |n| n['notifiable']['id'] == pin.id }

    assert_equal 1, group['notifiers_count']
    assert_equal [users(:you).id], group['notifiers'].pluck('id')
  end

  test 'index keeps different actions on the same subject apart' do
    pin = pins(:public_one)
    %w[liked comment].each do |key|
      Notification.create!(notifiable: pin, notifier: users(:you), recipient: users(:me), key: key)
    end

    stub_google_auth(users(:me)) do
      get '/v2/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    groups = JSON.parse(@response.body)['data'].select { |n| n['notifiable']['id'] == pin.id }

    assert_equal %w[comment liked], groups.pluck('key')
  end

  test 'index reads a group as read once all of it is read' do
    pin = pins(:public_one)
    2.times { Notification.create!(notifiable: pin, notifier: users(:you), recipient: users(:me), key: 'liked', read: true) }

    stub_google_auth(users(:me)) do
      get '/v2/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert JSON.parse(@response.body)['data'].find { |n| n['notifiable']['id'] == pin.id }['read']
  end

  test 'index leaves out the notifications of notifiers that no longer exist' do
    pin = pins(:public_one)
    live = Notification.create!(notifiable: pin, notifier: users(:you), recipient: users(:me), key: 'liked')
    missing_notifier_ids = [User.maximum(:id) + 1, User.maximum(:id) + 2]
    missing_notifier_ids.each do |notifier_id|
      Notification.create!(notifiable: pin, notifier: users(:me), recipient: users(:me), key: 'liked')
                  .update_column(:notifier_id, notifier_id)
    end

    stub_google_auth(users(:me)) do
      get '/v2/me/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    group = JSON.parse(@response.body)['data'].find { |n| n['key'] == 'liked' && n['notifiable']['id'] == pin.id }

    assert_equal live.id, group['id']
    assert_equal [users(:you).id], group['notifiers'].pluck('id')
    assert_equal 1, group['notifiers_count']
  end

  test 'index without a token should be unauthorized' do
    get '/v2/me/notifications'

    assert_response :unauthorized
  end
end
