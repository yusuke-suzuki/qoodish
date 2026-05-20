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

  test 'update accepts legacy image_url and converts to image_ids' do
    map = maps(:public_one)
    url = 'https://storage.googleapis.com/qoodish.appspot.com/maps/map-legacy.jpg'

    stub_google_auth(users(:me)) do
      stub_cloudflare_images do
        put "/maps/#{map.id}",
            params: { image_url: url },
            headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    images = map.reload.images
    assert_equal [url], images.map(&:url)
    assert_equal [users(:me).id], images.map(&:user_id).uniq
  end

  test 'update silently drops legacy image_url already owned by another user' do
    foreign_url = 'https://imagedelivery.net/mockhash/foreign-map/public'
    users(:you).owned_images.create!(url: foreign_url)
    map = maps(:public_one)

    stub_google_auth(users(:me)) do
      stub_cloudflare_images do
        put "/maps/#{map.id}",
            params: { image_url: foreign_url },
            headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_empty map.reload.images
  end
end
