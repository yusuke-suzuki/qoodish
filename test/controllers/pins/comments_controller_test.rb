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

  test 'create records the first revision' do
    stub_google_auth(users(:you)) do
      post "/pins/#{pins(:public_one).id}/comments",
           params: { comment: 'Nice place' },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert_equal 1, Comment.last.revisions.count
    assert_equal users(:you), Comment.last.current_revision.user
  end

  test 'create without a body raises unprocessable content error' do
    stub_google_auth(users(:you)) do
      post "/pins/#{pins(:public_one).id}/comments",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
  end

  test 'update rewrites own comment and appends a revision' do
    pin = pins(:public_one)

    assert_difference -> { comments(:one).revisions.count }, 1 do
      stub_google_auth(users(:me)) do
        patch "/pins/#{pin.id}/comments/#{comments(:one).id}",
              params: { comment: 'Second thoughts' },
              headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_equal 'Second thoughts', comments(:one).reload.body

    res = JSON.parse(@response.body)

    assert_includes res['comments'].map { |comment| comment['body'] }, 'Second thoughts'
  end

  test 'update a comment of another user raises not found error' do
    stub_google_auth(users(:me)) do
      patch "/pins/#{pins(:public_one).id}/comments/#{comments(:two).id}",
            params: { comment: 'Not mine' },
            headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
    assert_equal 'This is another comment', comments(:two).reload.body
  end

  test 'update a comment already removed raises not found error' do
    comments(:one).discard!(user: users(:me))

    stub_google_auth(users(:me)) do
      patch "/pins/#{pins(:public_one).id}/comments/#{comments(:one).id}",
            params: { comment: 'Back again' },
            headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'update without a body raises unprocessable content error' do
    stub_google_auth(users(:me)) do
      patch "/pins/#{pins(:public_one).id}/comments/#{comments(:one).id}",
            headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
    assert_equal 'This is a comment', comments(:one).reload.body
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

  test 'destroy records the removal as a revision' do
    assert_difference -> { comments(:one).revisions.count }, 1 do
      stub_google_auth(users(:me)) do
        delete "/pins/#{pins(:public_one).id}/comments/#{comments(:one).id}",
               headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_predicate comments(:one).reload.current_revision, :deleted?
  end

  test 'destroy a comment already removed raises not found error' do
    comments(:one).discard!(user: users(:me))

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

  test 'update without a token should be unauthorized' do
    patch "/pins/#{pins(:public_one).id}/comments/#{comments(:one).id}", params: { comment: 'Edited' }

    assert_response :unauthorized
  end
end
