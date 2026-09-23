require 'test_helper'

class Chapters::Comments::LikesControllerTest < ActionDispatch::IntegrationTest
  test 'create likes the comment' do
    comment = comments(:on_my_published_chapter)

    assert_difference 'Vote.count', 1 do
      stub_google_auth(users(:me)) do
        post "/chapters/#{chapters(:my_published).id}/comments/#{comment.id}/like",
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_equal comment, Vote.last.votable
    assert_equal users(:me), Vote.last.voter

    res = JSON.parse(@response.body)

    assert_equal comment.id, res['id']
    assert_equal 1, res['likes_count']
    assert res['liked']
  end

  test 'destroy unlikes the comment' do
    comment = comments(:on_my_published_chapter)

    users(:me).liked!(comment)

    assert_difference 'Vote.count', -1 do
      stub_google_auth(users(:me)) do
        delete "/chapters/#{chapters(:my_published).id}/comments/#{comment.id}/like",
               headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal 0, res['likes_count']
    assert_not res['liked']
  end

  test 'create on a comment left on another chapter raises not found error' do
    stub_google_auth(users(:me)) do
      post "/chapters/#{chapters(:you_published).id}/comments/#{comments(:on_my_published_chapter).id}/like",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'create on a chapter the user cannot read raises not found error' do
    stub_google_auth(users(:me)) do
      post "/chapters/#{chapters(:you_private_published_unfollowing).id}/comments/#{comments(:on_my_published_chapter).id}/like",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'create without a token should be unauthorized' do
    post "/chapters/#{chapters(:my_published).id}/comments/#{comments(:on_my_published_chapter).id}/like"

    assert_response :unauthorized
  end
end
