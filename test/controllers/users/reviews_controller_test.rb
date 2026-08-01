require 'test_helper'

class Users::ReviewsControllerTest < ActionDispatch::IntegrationTest
  test 'index of another user returns reviews on referenceable maps only' do
    stub_google_auth(users(:me)) do
      get "/users/#{users(:you).id}/reviews",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)
    ids = res.map { |review| review['id'] }

    assert_includes ids, reviews(:public_you_one).id
    assert_includes ids, reviews(:private_you).id
    assert_not_includes ids, reviews(:private_unfollowing_you).id
    assert(res.all? { |review| review['author']['id'] == users(:you).id })
  end

  test 'index without authentication should raise unauthorized error' do
    get "/users/#{users(:you).id}/reviews"

    assert_response :unauthorized
  end
end
