require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  test 'request to my profile should return the public payload' do
    stub_google_auth(users(:me)) do
      get "/users/#{users(:me).id}", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal res['uid'], users(:me).uid
    assert res['push_notification'].blank?
  end

  test 'request to your profile should be success' do
    stub_google_auth(users(:you)) do
      get "/users/#{users(:you).id}", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal res['id'], users(:you).id
    assert res['push_notification'].blank?
  end

  test 'signing up should record the name the account starts with' do
    newcomer = User.new(uid: 'newcomer-uid', name: 'Newcomer')

    assert_difference 'User.count', 1 do
      stub_google_auth(newcomer) do
        post '/users', headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    created = User.find_by!(uid: 'newcomer-uid')

    assert_equal 'Newcomer', created.name
    assert_equal 1, created.revisions.count
    assert_equal created.revisions.last, created.current_revision
    assert_equal 'Newcomer', created.current_revision.name
  end

  test 'signing up again should return the existing account' do
    assert_no_difference 'User.count' do
      stub_google_auth(users(:me)) do
        post '/users', headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal users(:me).id, res['id']
  end

  test 'request with a uid should raise not found error' do
    stub_google_auth(users(:me)) do
      get "/users/#{users(:me).uid}", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'search users by name should return matches' do
    stub_google_auth(users(:me)) do
      get '/users', params: { q: 'okayu' }, headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.any? { |user| user['id'] == users(:you).id })
  end

  test 'signing up records the email and the locale from the request' do
    newcomer = User.new(uid: 'newcomer1234', name: 'newcomer', email: 'newcomer@qoodish.com')

    stub_google_auth(newcomer) do
      post '/users', headers: { 'Authorization': 'Bearer dummytoken', 'Accept-Language': 'ja' }
    end

    assert_response :success

    created = User.find_by!(uid: 'newcomer1234')

    assert_equal 'newcomer@qoodish.com', created.email
    assert_equal 'ja', created.locale
  end

  test 'signing in again follows the language the user switched to' do
    users(:me).update!(locale: 'en')

    stub_google_auth(users(:me)) do
      post '/users', headers: { 'Authorization': 'Bearer dummytoken', 'Accept-Language': 'ja' }
    end

    assert_response :success
    assert_equal 'ja', users(:me).reload.locale
  end

  test 'search users without name should return empty' do
    stub_google_auth(users(:me)) do
      get '/users', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_empty res
  end
end
