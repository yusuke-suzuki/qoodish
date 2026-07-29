require 'test_helper'

class Me::PreferencesControllerTest < ActionDispatch::IntegrationTest
  test 'update stores the web push preferences' do
    stub_google_auth(users(:me)) do
      put '/me/preferences',
          params: {
            web_push: {
              coauthor_invited: false,
              liked: false,
              comment: false,
              published: false
            }
          },
          as: :json,
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    preferences = users(:me).reload.web_push_preferences

    assert_not preferences['coauthor_invited']
    assert_not preferences['liked']
    assert_not preferences['comment']
    assert_not preferences['published']
  end

  test 'update keeps the web push preferences it was not sent' do
    users(:me).update_web_push_preferences!('published' => false)

    stub_google_auth(users(:me)) do
      put '/me/preferences',
          params: { web_push: { liked: false } },
          as: :json,
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    preferences = users(:me).reload.web_push_preferences

    assert_not preferences['liked']
    assert_not preferences['published']
    assert preferences['comment']
  end

  test 'update responds with the effective web push preferences' do
    stub_google_auth(users(:me)) do
      put '/me/preferences',
          params: { web_push: { liked: false } },
          as: :json,
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal false, res['web_push']['liked']
    assert_equal true, res['web_push']['published']
  end

  test 'update rejects a value that is not a boolean' do
    stub_google_auth(users(:me)) do
      put '/me/preferences',
          params: { web_push: { liked: 'no' } },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
    assert users(:me).web_push_preferences['liked']
  end

  test 'update without web_push should raise bad request error' do
    stub_google_auth(users(:me)) do
      put '/me/preferences',
          params: {},
          as: :json,
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :bad_request
  end

  test 'update without a token should be unauthorized' do
    put '/me/preferences',
        params: { web_push: { liked: false } },
        as: :json

    assert_response :unauthorized
  end
end
