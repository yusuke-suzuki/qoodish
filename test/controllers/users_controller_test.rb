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

  test 'update accepts legacy image_path and converts to image_ids' do
    url = 'https://storage.googleapis.com/qoodish.appspot.com/profile/user-legacy.jpg'

    stub_google_auth(users(:me)) do
      stub_cloudflare_images do
        put "/users/#{users(:me).uid}",
            params: { image_path: url },
            headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    images = users(:me).reload.images
    assert_equal [url], images.map(&:url)
    assert_equal [users(:me).id], images.map(&:user_id).uniq
  end

  test 'update silently drops legacy image_path already owned by another user' do
    foreign_url = 'https://imagedelivery.net/mockhash/foreign-user/public'
    users(:you).owned_images.create!(url: foreign_url)

    stub_google_auth(users(:me)) do
      stub_cloudflare_images do
        put "/users/#{users(:me).uid}",
            params: { image_path: foreign_url },
            headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_empty users(:me).reload.images
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
