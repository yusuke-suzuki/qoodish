require 'test_helper'

class Users::BlocksControllerTest < ActionDispatch::IntegrationTest
  HEADERS = { 'Authorization': 'Bearer dummytoken' }.freeze

  test 'block another account' do
    assert_difference 'Block.count', 1 do
      stub_google_auth(users(:me)) do
        post "/users/#{users(:you).id}/block", headers: HEADERS
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal users(:you).id, res['id']
    assert res['blocking']
    assert_not res['blocked_by']
  end

  test 'blocking an account already blocked succeeds without recording another block' do
    users(:me).block!(users(:you))

    assert_no_difference 'Block.count' do
      stub_google_auth(users(:me)) do
        post "/users/#{users(:you).id}/block", headers: HEADERS
      end
    end

    assert_response :success
    assert JSON.parse(@response.body)['blocking']
  end

  test 'blocking your own account is refused' do
    stub_google_auth(users(:me)) do
      post "/users/#{users(:me).id}/block", headers: HEADERS
    end

    assert_response :unprocessable_content
  end

  test 'unblock an account' do
    users(:me).block!(users(:you))

    assert_difference 'Unblock.count', 1 do
      assert_no_difference 'Block.count' do
        stub_google_auth(users(:me)) do
          delete "/users/#{users(:you).id}/block", headers: HEADERS
        end
      end
    end

    assert_response :success
    assert_not JSON.parse(@response.body)['blocking']
  end

  test 'unblocking lifts every block recorded at once' do
    Block.create!(blocker: users(:me), blocked: users(:you))
    Block.new(blocker: users(:me), blocked: users(:you)).save!(validate: false)

    stub_google_auth(users(:me)) do
      delete "/users/#{users(:you).id}/block", headers: HEADERS
    end

    assert_response :success
    assert_not users(:me).blocking?(users(:you))
    assert_equal 2, Unblock.where(block: users(:me).blocks).count
  end

  test 'block again after unblocking' do
    block = users(:me).block!(users(:you))
    Unblock.create!(block: block)

    stub_google_auth(users(:me)) do
      post "/users/#{users(:you).id}/block", headers: HEADERS
    end

    assert_response :success
    assert JSON.parse(@response.body)['blocking']
    assert_equal 2, users(:me).blocks.count
  end

  test 'unblocking an account that is not blocked succeeds without recording a lift' do
    assert_no_difference 'Unblock.count' do
      stub_google_auth(users(:me)) do
        delete "/users/#{users(:you).id}/block", headers: HEADERS
      end
    end

    assert_response :success
    assert_not JSON.parse(@response.body)['blocking']
  end

  test 'a blocked account learns it is blocked from the profile' do
    users(:me).block!(users(:you))

    stub_google_auth(users(:you)) do
      get "/users/#{users(:me).id}", headers: HEADERS
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert res['blocked_by']
    assert_not res['blocking']
  end

  test 'a blocked account cannot open the content of the account that blocked it' do
    users(:me).block!(users(:you))

    stub_google_auth(users(:you)) do
      get "/pins/#{pins(:public_one).id}", headers: HEADERS
      assert_response :not_found

      get "/maps/#{maps(:public_one).id}", headers: HEADERS
      assert_response :not_found

      get "/chapters/#{chapters(:my_published).id}", headers: HEADERS
      assert_response :not_found

      get "/journals/#{journals(:my_journal).id}", headers: HEADERS
      assert_response :not_found

      get "/users/#{users(:me).id}/maps", headers: HEADERS
      assert_empty JSON.parse(@response.body)
    end
  end

  test 'a blocked account cannot comment on or like the content of the account that blocked it' do
    users(:me).block!(users(:you))

    stub_google_auth(users(:you)) do
      post "/pins/#{pins(:public_one).id}/comments", params: { comment: 'hello' }, headers: HEADERS
      assert_response :not_found

      post "/chapters/#{chapters(:my_published).id}/like", headers: HEADERS
      assert_response :not_found
    end
  end

  test 'the blocking account cannot like the content of the blocked account' do
    users(:me).block!(users(:you))

    stub_google_auth(users(:me)) do
      post "/pins/#{pins(:public_unfollowing_you).id}/like", headers: HEADERS
    end

    assert_response :unprocessable_content
  end

  test 'the blocking account no longer sees the blocked account in its feed' do
    users(:me).block!(users(:you))

    stub_google_auth(users(:me)) do
      get '/pins', headers: HEADERS
    end

    assert_response :success

    author_ids = JSON.parse(@response.body).map { |pin| pin['author']['id'] }

    assert_not_includes author_ids, users(:you).id
  end

  test 'content of a blocked account tells the blocking account that its author is blocked' do
    users(:me).block!(users(:you))

    stub_google_auth(users(:me)) do
      get "/pins/#{pins(:public_unfollowing_you).id}", headers: HEADERS
      assert JSON.parse(@response.body)['author']['blocking']

      get "/maps/#{maps(:public_unfollowing).id}", headers: HEADERS
      assert JSON.parse(@response.body)['author']['blocking']

      get "/chapters/#{chapters(:you_published).id}", headers: HEADERS
      assert JSON.parse(@response.body)['author']['blocking']
    end
  end

  test 'content of an account that is not blocked says its author is not blocked' do
    stub_google_auth(users(:me)) do
      get "/pins/#{pins(:public_unfollowing_you).id}", headers: HEADERS
    end

    assert_equal false, JSON.parse(@response.body)['author']['blocking']
  end

  test 'comments across a block are hidden on both sides' do
    users(:me).block!(users(:you))

    stub_google_auth(users(:me)) do
      get "/pins/#{pins(:public_one).id}", headers: HEADERS
      comment_ids = JSON.parse(@response.body)['comments'].pluck('id')

      assert_includes comment_ids, comments(:one).id
      assert_not_includes comment_ids, comments(:two).id

      get "/chapters/#{chapters(:my_published).id}/comments", headers: HEADERS
      assert_not_includes JSON.parse(@response.body).pluck('id'), comments(:on_my_published_chapter).id
    end
  end

  test 'comment counts leave out comments across a block either way' do
    users(:you).block!(users(:me))

    stub_google_auth(users(:me)) do
      get "/chapters/#{chapters(:my_published).id}", headers: HEADERS
      assert_equal 0, JSON.parse(@response.body)['comments_count']

      get "/me/chapters/#{chapters(:my_published).id}", headers: HEADERS
      assert_equal 0, JSON.parse(@response.body)['comments_count']
    end
  end

  test 'comments across a block cannot be liked' do
    users(:me).block!(users(:you))

    stub_google_auth(users(:me)) do
      post "/pins/#{pins(:public_one).id}/comments/#{comments(:two).id}/like", headers: HEADERS
      assert_response :not_found

      get "/pins/#{pins(:public_one).id}/comments/#{comments(:two).id}/likes", headers: HEADERS
      assert_response :not_found

      post "/chapters/#{chapters(:my_published).id}/comments/#{comments(:on_my_published_chapter).id}/like",
           headers: HEADERS
      assert_response :not_found
    end
  end

  test 'notifications from a blocked account are hidden' do
    notification = Notification.create!(notifiable: pins(:public_one), notifier: users(:you), recipient: users(:me), key: 'liked')
    users(:me).block!(users(:you))

    stub_google_auth(users(:me)) do
      get '/me/notifications', headers: HEADERS
      assert_response :success
      assert_empty JSON.parse(@response.body)

      patch "/me/notifications/#{notification.id}", headers: HEADERS
      assert_response :not_found
    end
  end

  test 'a blocked account does not find the account that blocked it' do
    users(:me).block!(users(:you))

    stub_google_auth(users(:you)) do
      get '/users', params: { q: users(:me).name }, headers: HEADERS
    end

    assert_response :success
    assert_empty JSON.parse(@response.body)
  end
end
