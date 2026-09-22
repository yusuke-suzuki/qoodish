require 'test_helper'

class Pins::Comments::LikesControllerTest < ActionDispatch::IntegrationTest
  test 'create likes the comment' do
    pin = pins(:public_one)

    assert_difference 'Vote.count', 1 do
      stub_google_auth(users(:me)) do
        post "/pins/#{pin.id}/comments/#{comments(:two).id}/like",
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_equal comments(:two), Vote.last.votable
    assert_equal users(:me), Vote.last.voter

    liked = JSON.parse(@response.body)['comments'].find { |it| it['id'] == comments(:two).id }

    assert_equal 1, liked['likes_count']
    assert liked['liked']
  end

  test 'destroy unlikes the comment' do
    users(:me).liked!(comments(:two))

    assert_difference 'Vote.count', -1 do
      stub_google_auth(users(:me)) do
        delete "/pins/#{pins(:public_one).id}/comments/#{comments(:two).id}/like",
               headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
  end

  test 'create on a comment of another pin raises not found error' do
    stub_google_auth(users(:me)) do
      post "/pins/#{pins(:public_two).id}/comments/#{comments(:one).id}/like",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'create without a token should be unauthorized' do
    post "/pins/#{pins(:public_one).id}/comments/#{comments(:two).id}/like"

    assert_response :unauthorized
  end
end
