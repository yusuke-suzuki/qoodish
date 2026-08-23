require 'test_helper'

class MapsControllerTest < ActionDispatch::IntegrationTest
  test 'request to single my map should be success' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:public_one).id}", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal res['id'], maps(:public_one).id
  end

  test 'request to single unfollowing private map should raise not found error' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:private_unfollowing).id}", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'request to single following private map should be success' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:private_following).id}", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal res['id'], maps(:private_following).id
  end

  test 'coauthor cannot change the private flag' do
    map = maps(:private_following) # author: you, coauthor: me

    stub_google_auth(users(:me)) do
      patch "/maps/#{map.id}", params: { private: false }, headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert map.reload.private
  end

  test 'update should succeed when the map already holds more images than the limit' do
    map = maps(:public_one) # author: me

    2.times do |i|
      users(:me).owned_images.create!(
        imageable: map,
        url: "https://imagedelivery.net/mockhash/map-legacy-#{i}/public"
      )
    end

    stub_google_auth(users(:me)) do
      patch "/maps/#{map.id}", params: { name: 'Renamed' }, headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert_equal 'Renamed', map.reload.name
    assert_equal 2, map.images.count
  end

  test 'update with more image_ids than the limit should raise unprocessable error' do
    map = maps(:public_one) # author: me

    image_ids = Array.new(2) do |i|
      users(:me).owned_images.create!(
        url: "https://imagedelivery.net/mockhash/map-limit-#{i}/public"
      ).id
    end

    stub_google_auth(users(:me)) do
      patch "/maps/#{map.id}",
            params: { image_ids: image_ids },
            headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
  end

  test 'author can change the private flag' do
    map = maps(:public_one) # author: me

    stub_google_auth(users(:me)) do
      patch "/maps/#{map.id}", params: { private: true }, headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert map.reload.private
  end
end
