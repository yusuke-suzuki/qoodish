require 'test_helper'

class Pins::CommentsControllerTest < ActionDispatch::IntegrationTest
  test 'create adds a comment and returns the pin' do
    pin = pins(:public_one)

    assert_difference 'Comment.count', 1 do
      stub_google_auth(users(:you)) do
        post "/pins/#{pin.id}/comments",
             params: { comment: 'Nice place' },
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal pin.id, res['id']
    assert_includes res['comments'].map { |comment| comment['body'] }, 'Nice place'
    assert_equal pin, Comment.last.commentable
    assert_equal users(:you), Comment.last.user
  end

  test 'create without a body raises unprocessable content error' do
    stub_google_auth(users(:you)) do
      post "/pins/#{pins(:public_one).id}/comments",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
  end

  test 'destroy removes own comment' do
    pin = pins(:public_one)

    assert_no_difference 'Comment.count' do
      stub_google_auth(users(:me)) do
        delete "/pins/#{pin.id}/comments/#{comments(:one).id}",
               headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_predicate comments(:one).reload, :deleted?

    res = JSON.parse(@response.body)

    assert_not_includes res['comments'].map { |comment| comment['id'] }, comments(:one).id
  end

  test 'destroy a comment already removed raises not found error' do
    comments(:one).discard!

    stub_google_auth(users(:me)) do
      delete "/pins/#{pins(:public_one).id}/comments/#{comments(:one).id}",
             headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'destroy a comment of another user raises not found error' do
    assert_no_difference 'Comment.count' do
      stub_google_auth(users(:me)) do
        delete "/pins/#{pins(:public_one).id}/comments/#{comments(:two).id}",
               headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :not_found
  end

  test 'create on a pin the user cannot reference raises not found error' do
    stub_google_auth(users(:me)) do
      post "/pins/#{pins(:private_unfollowing_you).id}/comments",
           params: { comment: 'Nice place' },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'create without a token should be unauthorized' do
    post "/pins/#{pins(:public_one).id}/comments", params: { comment: 'Nice place' }

    assert_response :unauthorized
  end
end
