require 'test_helper'

class NotificationsControllerTest < ActionDispatch::IntegrationTest
  test 'index renders successfully when notifiable is a Review' do
    review = reviews(:public_one)
    Notification.create!(
      notifiable: review,
      notifier: users(:you),
      recipient: users(:me),
      key: 'liked'
    )

    stub_google_auth(users(:me)) do
      get '/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    body = JSON.parse(@response.body)
    notification = body.find { |n| n['notifiable']['id'] == review.id && n['notifiable']['type'] == 'review' }
    assert notification
    # image_variants returns a hash when the notifiable has images, else null.
    assert notification['notifiable'].key?('image')
  end

  test 'index renders successfully when notifiable is a Comment' do
    comment = comments(:one)
    Notification.create!(
      notifiable: comment,
      notifier: users(:you),
      recipient: users(:me),
      key: 'liked'
    )

    stub_google_auth(users(:me)) do
      get '/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    body = JSON.parse(@response.body)
    notification = body.find { |n| n['notifiable']['id'] == comment.id && n['notifiable']['type'] == 'comment' }
    assert notification
    assert notification['notifiable'].key?('image')
  end

  test 'index renders successfully when notifiable is a Map' do
    map = maps(:private)
    Notification.create!(
      notifiable: map,
      notifier: users(:you),
      recipient: users(:me),
      key: 'followed'
    )

    stub_google_auth(users(:me)) do
      get '/notifications', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
  end
end
