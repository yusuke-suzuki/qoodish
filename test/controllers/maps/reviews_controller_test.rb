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

  test 'request to single review on unfollowing private map should raise not found error' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:private_unfollowing).id}/reviews/#{reviews(:private_unfollowing).id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'request to single review on following private map should be success' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:private_following).id}/reviews/#{reviews(:private_following).id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal res['id'], reviews(:private_following).id
  end

  test 'request to single review on public map should be success' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:public_one).id}/reviews/#{reviews(:public_one).id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal res['id'], reviews(:public_one).id
  end
end
