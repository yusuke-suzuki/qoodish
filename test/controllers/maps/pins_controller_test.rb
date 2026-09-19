require 'test_helper'

class Maps::PinsControllerTest < ActionDispatch::IntegrationTest
  test 'list of pins on a unfollowing private map should be empty' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:private_unfollowing).id}/pins", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_empty(res)
  end

  test 'list of pins on a following private map should be success' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:private_following).id}/pins", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |pin| pin['map']['id'] == maps(:private_following).id })
  end

  test 'list of pins on a public map should be success' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:public_one).id}/pins", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |pin| pin['map']['id'] == maps(:public_one).id })
  end

  test 'create publishes a pin with its first revision' do
    stub_google_auth(users(:me)) do
      post "/maps/#{maps(:public_one).id}/pins",
           params: {
             name: 'Cafe Bonjour',
             comment: 'Nice place',
             latitude: 35.681382,
             longitude: 139.766084
           },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)
    pin = Pin.find(res['id'])

    assert_equal 'Cafe Bonjour', pin.name
    assert_equal 1, pin.revisions.count
    assert_equal pin.current_revision, pin.revisions.last
  end

  test 'create on a map the user cannot edit should raise not found error' do
    stub_google_auth(users(:me)) do
      post "/maps/#{maps(:public_unfollowing).id}/pins",
           params: {
             name: 'Cafe Bonjour',
             comment: 'Nice place',
             latitude: 35.681382,
             longitude: 139.766084
           },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end
end
