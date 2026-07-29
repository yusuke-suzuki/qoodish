require 'test_helper'

class Me::AccountsControllerTest < ActionDispatch::IntegrationTest
  test 'destroy should delete the account' do
    uid = users(:me).uid

    stub_google_auth(users(:me)) do
      stub_identity_platform do
        stub_cloudflare_images do
          delete '/me/account', headers: { 'Authorization': 'Bearer dummytoken' }
        end
      end
    end

    assert_response :no_content
    assert_nil User.find_by(uid: uid)
  end

  test 'destroy without a token should be unauthorized' do
    delete '/me/account'

    assert_response :unauthorized
  end
end
