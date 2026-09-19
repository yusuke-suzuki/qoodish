require 'test_helper'

class Users::PinsControllerTest < ActionDispatch::IntegrationTest
  test 'index of another user returns pins on referenceable maps only' do
    stub_google_auth(users(:me)) do
      get "/users/#{users(:you).id}/pins",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)
    ids = res.map { |pin| pin['id'] }

    assert_includes ids, pins(:public_you_one).id
    assert_includes ids, pins(:private_you).id
    assert_not_includes ids, pins(:private_unfollowing_you).id
    assert(res.all? { |pin| pin['author']['id'] == users(:you).id })
  end

  test 'index without authentication should raise unauthorized error' do
    get "/users/#{users(:you).id}/pins"

    assert_response :unauthorized
  end
end
