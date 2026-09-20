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

  test 'update should set the avatar from a one-element image_ids' do
    stub_google_auth(users(:me)) do
      put '/me/profile',
          params: { image_ids: [images(:one).id] },
          headers: { 'Authorization': 'Bearer dummytoken' },
          as: :json
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal images(:one).url, res['image_url']
    assert_equal images(:one), users(:me).reload.image
  end

  test 'update should clear the avatar when image_ids is empty' do
    users(:me).update!(image: images(:one))

    stub_google_auth(users(:me)) do
      put '/me/profile',
          params: { image_ids: [] },
          headers: { 'Authorization': 'Bearer dummytoken' },
          as: :json
    end

    assert_response :success
    assert_nil users(:me).reload.image_id
  end

  test 'update should leave the avatar alone when image_ids is not sent' do
    users(:me).update!(image: images(:one))

    stub_google_auth(users(:me)) do
      put '/me/profile',
          params: { name: 'Renamed' },
          headers: { 'Authorization': 'Bearer dummytoken' },
          as: :json
    end

    assert_response :success
    assert_equal images(:one), users(:me).reload.image
  end

  test 'update should reject an image that does not exist' do
    stub_google_auth(users(:me)) do
      put '/me/profile',
          params: { image_ids: [Image.maximum(:id).to_i + 1] },
          headers: { 'Authorization': 'Bearer dummytoken' },
          as: :json
    end

    assert_response :unprocessable_content
    assert_nil users(:me).reload.image_id
  end

  test 'update should reject an image another user uploaded' do
    foreign_image = users(:you).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/profile-foreign/public'
    )

    stub_google_auth(users(:me)) do
      put '/me/profile',
          params: { image_ids: [foreign_image.id] },
          headers: { 'Authorization': 'Bearer dummytoken' },
          as: :json
    end

    assert_response :unprocessable_content
    assert_nil users(:me).reload.image_id
  end

  test 'show without a token should be unauthorized' do
    get '/me/profile'

    assert_response :unauthorized
  end
end
