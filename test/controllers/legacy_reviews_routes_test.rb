require 'test_helper'

class LegacyReviewsRoutesTest < ActionDispatch::IntegrationTest
  test 'the review paths serve the same payload as the pin paths' do
    %W[
      /reviews/#{pins(:public_one).id}
      /me/reviews
      /maps/#{maps(:public_one).id}/reviews
      /users/#{users(:me).id}/reviews
    ].each do |path|
      stub_google_auth(users(:me)) do
        get path, headers: { 'Authorization': 'Bearer dummytoken' }
      end

      assert_response :success, "GET #{path}"
    end
  end

  test 'the guest review paths stay available' do
    get "/guest/reviews/#{pins(:public_one).id}"
    assert_response :success

    get '/guest/reviews', params: { recent: true }
    assert_response :success

    get "/guest/maps/#{maps(:public_one).id}/reviews"
    assert_response :success

    get "/guest/users/#{users(:me).id}/reviews"
    assert_response :success
  end

  test 'a comment posted through the review path lands on the pin' do
    pin = pins(:public_one)

    assert_difference 'Comment.count', 1 do
      stub_google_auth(users(:you)) do
        post "/reviews/#{pin.id}/comments",
             params: { comment: 'Posted through the legacy path' },
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_equal pin, Comment.last.commentable
  end

  test 'a pin revised through the review path appends a revision' do
    pin = pins(:public_one)

    assert_difference -> { pin.revisions.count }, 1 do
      stub_google_auth(users(:me)) do
        put "/me/reviews/#{pin.id}",
            params: { name: 'revised through the legacy path' },
            headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_equal 'revised through the legacy path', pin.reload.name
  end
end
