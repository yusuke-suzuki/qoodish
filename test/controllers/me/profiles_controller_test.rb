require 'test_helper'

class Me::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test 'show should return own profile with push notification preferences' do
    stub_google_auth(users(:me)) do
      get '/me/profile', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal users(:me).uid, res['uid']
    assert_equal %w[coauthor_invited liked comment published],
                 res['push_notification'].keys
    assert res['push_notification'].values.all?
  end

  test 'update should change name and biography' do
    stub_google_auth(users(:me)) do
      put '/me/profile',
          params: { name: 'Renamed', biography: 'Updated biography' },
          headers: { 'Authorization': 'Bearer dummytoken' },
          as: :json
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal 'Renamed', res['name']
    assert_equal 'Updated biography', res['biography']
    assert_equal 'Renamed', users(:me).reload.name
  end

  test 'update should succeed when the user already holds more images than the limit' do
    2.times do |i|
      users(:me).owned_images.create!(
        imageable: users(:me),
        url: "https://imagedelivery.net/mockhash/profile-legacy-#{i}/public"
      )
    end

    stub_google_auth(users(:me)) do
      put '/me/profile',
          params: { name: 'Renamed' },
          headers: { 'Authorization': 'Bearer dummytoken' },
          as: :json
    end

    assert_response :success
    assert_equal 'Renamed', users(:me).reload.name
  end

  test 'show without a token should be unauthorized' do
    get '/me/profile'

    assert_response :unauthorized
  end
end
