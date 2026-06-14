require 'test_helper'

class UsersControllerTest < ActionDispatch::IntegrationTest
  test 'request to my profile with uid should be success' do
    stub_google_auth(users(:me)) do
      get "/users/#{users(:me).uid}", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal res['uid'], users(:me).uid
    assert res['push_notification'].present?
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

  test 'delete account should be success' do
    uid = users(:me).uid

    stub_google_auth(users(:me)) do
      stub_identity_platform do
        stub_cloudflare_images do
          delete "/users/#{uid}", headers: { 'Authorization': 'Bearer dummytoken' }
        end
      end
    end

    assert_response :no_content
    assert_nil User.find_by(uid: uid)
  end
end
