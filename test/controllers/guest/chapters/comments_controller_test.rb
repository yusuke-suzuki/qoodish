require 'test_helper'

class Guest::Chapters::CommentsControllerTest < ActionDispatch::IntegrationTest
  test 'index returns the comments left on a public chapter' do
    get "/guest/chapters/#{chapters(:my_published).id}/comments"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal [comments(:on_my_published_chapter).id], res.map { |comment| comment['id'] }
    assert_equal 'This is a comment on a chapter', res.first['body']
    assert_equal users(:you).id, res.first['author']['id']
  end

  test 'index does not tell a guest whether a comment is editable' do
    get "/guest/chapters/#{chapters(:my_published).id}/comments"

    assert_not_includes JSON.parse(@response.body).first.keys, 'editable'
  end

  test 'index does not tell a guest whether a comment was liked' do
    users(:me).liked!(comments(:on_my_published_chapter))

    get "/guest/chapters/#{chapters(:my_published).id}/comments"

    assert_not_includes JSON.parse(@response.body).first.keys, 'liked'
  end

  test 'index does not serve a comment that was taken down' do
    comments(:on_my_published_chapter).discard!(user: users(:you))

    get "/guest/chapters/#{chapters(:my_published).id}/comments"

    assert_response :success
    assert_empty JSON.parse(@response.body)
  end

  test 'index on a draft chapter raises not found error' do
    get "/guest/chapters/#{chapters(:my_draft).id}/comments"

    assert_response :not_found
  end

  test 'index on a chapter of a private map raises not found error' do
    get "/guest/chapters/#{chapters(:you_private_published_unfollowing).id}/comments"

    assert_response :not_found
  end
end
