require 'test_helper'

class Chapters::CommentsControllerTest < ActionDispatch::IntegrationTest
  test 'index returns the comments left on the chapter' do
    stub_google_auth(users(:me)) do
      get "/chapters/#{chapters(:my_published).id}/comments",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal [comments(:on_my_published_chapter).id], res.map { |comment| comment['id'] }
    assert_equal users(:you).id, res.first['author']['id']
    assert_not res.first['editable']
  end

  test 'index does not serve a comment that was taken down' do
    comments(:on_my_published_chapter).discard!(user: users(:you))

    stub_google_auth(users(:me)) do
      get "/chapters/#{chapters(:my_published).id}/comments",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert_empty JSON.parse(@response.body)
  end

  test 'index tells the caller how the comment was received' do
    users(:me).liked!(comments(:on_my_published_chapter))

    stub_google_auth(users(:me)) do
      get "/chapters/#{chapters(:my_published).id}/comments",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    res = JSON.parse(@response.body).first

    assert res['liked']
    assert_equal 1, res['likes_count']
  end

  test 'index does not claim a like the caller never left' do
    users(:you).liked!(comments(:on_my_published_chapter))

    stub_google_auth(users(:me)) do
      get "/chapters/#{chapters(:my_published).id}/comments",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    res = JSON.parse(@response.body).first

    assert_not res['liked']
    assert_equal 1, res['likes_count']
  end

  test 'index marks the caller own comment editable' do
    stub_google_auth(users(:you)) do
      get "/chapters/#{chapters(:my_published).id}/comments",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert JSON.parse(@response.body).first['editable']
  end

  test 'create adds a comment and records the first revision' do
    chapter = chapters(:my_published)

    assert_difference 'Comment.count', 1 do
      stub_google_auth(users(:you)) do
        post "/chapters/#{chapter.id}/comments",
             params: { comment: 'A considered reply' },
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal 'A considered reply', res['body']
    assert_equal chapter, Comment.last.commentable
    assert_equal 1, Comment.last.revisions.count
  end

  test 'create notifies the author of the chapter' do
    assert_difference 'Notification.count', 1 do
      stub_google_auth(users(:you)) do
        post "/chapters/#{chapters(:my_published).id}/comments",
             params: { comment: 'A considered reply' },
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    notification = Notification.last

    assert_equal chapters(:my_published), notification.notifiable
    assert_equal users(:me), notification.recipient
    assert_equal 'comment', notification.key
    assert_equal "/chapters/#{chapters(:my_published).id}", notification.click_action
  end

  test 'create without a body raises unprocessable content error' do
    stub_google_auth(users(:you)) do
      post "/chapters/#{chapters(:my_published).id}/comments",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
  end

  test 'create on a draft chapter of another user raises not found error' do
    stub_google_auth(users(:me)) do
      post "/chapters/#{chapters(:you_draft).id}/comments",
           params: { comment: 'Too early' },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'create on a chapter the user cannot reference raises not found error' do
    stub_google_auth(users(:me)) do
      post "/chapters/#{chapters(:you_private_published_unfollowing).id}/comments",
           params: { comment: 'Nice' },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'an author may comment on their own draft chapter' do
    assert_difference 'Comment.count', 1 do
      stub_google_auth(users(:me)) do
        post "/chapters/#{chapters(:my_draft).id}/comments",
             params: { comment: 'A note to myself' },
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
  end

  test 'update rewrites own comment and appends a revision' do
    comment = comments(:on_my_published_chapter)

    assert_difference -> { comment.revisions.count }, 1 do
      stub_google_auth(users(:you)) do
        patch "/chapters/#{chapters(:my_published).id}/comments/#{comment.id}",
              params: { comment: 'Second thoughts' },
              headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_equal 'Second thoughts', comment.reload.body
    assert_equal 'Second thoughts', JSON.parse(@response.body)['body']
  end

  test 'update a comment of another user raises not found error' do
    stub_google_auth(users(:me)) do
      patch "/chapters/#{chapters(:my_published).id}/comments/#{comments(:on_my_published_chapter).id}",
            params: { comment: 'Not mine' },
            headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
    assert_equal 'This is a comment on a chapter', comments(:on_my_published_chapter).reload.body
  end

  test 'update a comment left on another chapter raises not found error' do
    stub_google_auth(users(:you)) do
      patch "/chapters/#{chapters(:you_published).id}/comments/#{comments(:on_my_published_chapter).id}",
            params: { comment: 'Wrong chapter' },
            headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'destroy keeps the row and takes the comment off the chapter' do
    comment = comments(:on_my_published_chapter)

    assert_no_difference 'Comment.count' do
      stub_google_auth(users(:you)) do
        delete "/chapters/#{chapters(:my_published).id}/comments/#{comment.id}",
               headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_predicate comment.reload, :deleted?
    assert_predicate comment.current_revision, :deleted?
    assert_empty chapters(:my_published).comments.reload
  end

  test 'destroy a comment of another user raises not found error' do
    stub_google_auth(users(:me)) do
      delete "/chapters/#{chapters(:my_published).id}/comments/#{comments(:on_my_published_chapter).id}",
             headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'index without a token should be unauthorized' do
    get "/chapters/#{chapters(:my_published).id}/comments"

    assert_response :unauthorized
  end

  test 'create without a token should be unauthorized' do
    post "/chapters/#{chapters(:my_published).id}/comments", params: { comment: 'Nice' }

    assert_response :unauthorized
  end
end
