require 'test_helper'

class Pins::LikesControllerTest < ActionDispatch::IntegrationTest
  test 'create likes the pin and returns it' do
    pin = pins(:public_two)

    assert_difference 'Vote.count', 1 do
      stub_google_auth(users(:me)) do
        post "/pins/#{pin.id}/like", headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal pin.id, res['id']
    assert res['liked']
    assert_equal 1, res['likes_count']
  end

  test 'destroy unlikes the pin' do
    pin = pins(:public_one)

    assert_difference 'Vote.count', -1 do
      stub_google_auth(users(:me)) do
        delete "/pins/#{pin.id}/like", headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not res['liked']
  end

  test 'create on a pin the user cannot reference raises not found error' do
    stub_google_auth(users(:me)) do
      post "/pins/#{pins(:private_unfollowing_you).id}/like",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'create on a deleted pin raises not found error' do
    pin = pins(:public_two)
    pin.discard!(user: users(:me))

    stub_google_auth(users(:me)) do
      post "/pins/#{pin.id}/like", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'create without a token should be unauthorized' do
    post "/pins/#{pins(:public_two).id}/like"

    assert_response :unauthorized
  end
end
