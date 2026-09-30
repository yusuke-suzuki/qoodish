require 'test_helper'

class Users::MutesControllerTest < ActionDispatch::IntegrationTest
  HEADERS = { 'Authorization': 'Bearer dummytoken' }.freeze

  test 'mute another account' do
    assert_difference 'Mute.count', 1 do
      stub_google_auth(users(:me)) do
        post "/users/#{users(:you).id}/mute", headers: HEADERS
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal users(:you).id, res['id']
    assert res['muting']
  end

  test 'muting an account already muted succeeds without recording another mute' do
    users(:me).mute!(users(:you))

    assert_no_difference 'Mute.count' do
      stub_google_auth(users(:me)) do
        post "/users/#{users(:you).id}/mute", headers: HEADERS
      end
    end

    assert_response :success
    assert JSON.parse(@response.body)['muting']
  end

  test 'muting your own account is refused' do
    stub_google_auth(users(:me)) do
      post "/users/#{users(:me).id}/mute", headers: HEADERS
    end

    assert_response :unprocessable_content
  end

  test 'unmute an account' do
    users(:me).mute!(users(:you))

    assert_difference 'Unmute.count', 1 do
      assert_no_difference 'Mute.count' do
        stub_google_auth(users(:me)) do
          delete "/users/#{users(:you).id}/mute", headers: HEADERS
        end
      end
    end

    assert_response :success
    assert_not JSON.parse(@response.body)['muting']
  end

  test 'unmuting lifts every mute recorded at once' do
    Mute.create!(muter: users(:me), muted: users(:you))
    Mute.new(muter: users(:me), muted: users(:you)).save!(validate: false)

    stub_google_auth(users(:me)) do
      delete "/users/#{users(:you).id}/mute", headers: HEADERS
    end

    assert_response :success
    assert_not users(:me).muting?(users(:you))
    assert_equal 2, Unmute.where(mute: users(:me).mutes).count
  end

  test 'unmuting an account that is not muted succeeds without recording a lift' do
    assert_no_difference 'Unmute.count' do
      stub_google_auth(users(:me)) do
        delete "/users/#{users(:you).id}/mute", headers: HEADERS
      end
    end

    assert_response :success
    assert_not JSON.parse(@response.body)['muting']
  end

  test 'a muted account does not learn it is muted' do
    users(:me).mute!(users(:you))

    stub_google_auth(users(:you)) do
      get "/users/#{users(:me).id}", headers: HEADERS
    end

    res = JSON.parse(@response.body)

    assert_not res['muting']
    assert_not res['blocked_by']
  end

  test 'the muted account leaves the pin and chapter feeds' do
    users(:me).mute!(users(:you))

    stub_google_auth(users(:me)) do
      get '/pins', headers: HEADERS
      assert_not_includes JSON.parse(@response.body).map { |pin| pin['author']['id'] }, users(:you).id

      get '/chapters', headers: HEADERS
      assert_not_includes JSON.parse(@response.body).map { |chapter| chapter['author']['id'] }, users(:you).id
    end
  end

  test 'the content of a muted account can still be opened' do
    users(:me).mute!(users(:you))

    stub_google_auth(users(:me)) do
      get "/pins/#{pins(:public_unfollowing_you).id}", headers: HEADERS
    end

    assert_response :success
  end

  test 'comments by a muted account are hidden' do
    users(:me).mute!(users(:you))

    stub_google_auth(users(:me)) do
      get "/pins/#{pins(:public_one).id}", headers: HEADERS
      comment_ids = JSON.parse(@response.body)['comments'].pluck('id')

      assert_includes comment_ids, comments(:one).id
      assert_not_includes comment_ids, comments(:two).id

      get "/chapters/#{chapters(:my_published).id}/comments", headers: HEADERS
      assert_not_includes JSON.parse(@response.body).pluck('id'), comments(:on_my_published_chapter).id
    end
  end

  test 'comment counts leave out comments by a muted account' do
    users(:me).mute!(users(:you))

    stub_google_auth(users(:me)) do
      get "/chapters/#{chapters(:my_published).id}", headers: HEADERS
      assert_equal 0, JSON.parse(@response.body)['comments_count']

      get "/me/chapters/#{chapters(:my_published).id}", headers: HEADERS
      assert_equal 0, JSON.parse(@response.body)['comments_count']
    end
  end

  test 'the muted account still sees comments by the account that muted it' do
    users(:you).mute!(users(:me))

    stub_google_auth(users(:me)) do
      get "/pins/#{pins(:public_one).id}", headers: HEADERS
    end

    assert_includes JSON.parse(@response.body)['comments'].pluck('id'), comments(:two).id
  end

  test 'notifications from a muted account are hidden' do
    notification = Notification.create!(notifiable: pins(:public_one), notifier: users(:you), recipient: users(:me), key: 'liked')
    users(:me).mute!(users(:you))

    stub_google_auth(users(:me)) do
      get '/me/notifications', headers: HEADERS
      assert_response :success
      assert_empty JSON.parse(@response.body)

      patch "/me/notifications/#{notification.id}", headers: HEADERS
      assert_response :not_found
    end
  end
end
