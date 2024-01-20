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
end
