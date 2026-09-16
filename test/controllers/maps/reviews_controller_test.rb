require 'test_helper'

class Maps::ReviewsControllerTest < ActionDispatch::IntegrationTest
  test 'list of reviews on a unfollowing private map should be empty' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:private_unfollowing).id}/reviews", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_empty(res)
  end

  test 'list of reviews on a following private map should be success' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:private_following).id}/reviews", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |review| review['map']['id'] == maps(:private_following).id })
  end

  test 'list of reviews on a public map should be success' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:public_one).id}/reviews", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |review| review['map']['id'] == maps(:public_one).id })
  end
end
