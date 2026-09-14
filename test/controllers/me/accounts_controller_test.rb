require 'test_helper'

class Me::AccountsControllerTest < ActionDispatch::IntegrationTest
  test 'destroy should delete the account and list what went with it' do
    user = users(:me)
    expected = {
      'id' => user.id,
      'map_ids' => user.map_ids.sort,
      'review_ids' => user.review_ids.sort,
      'chapter_ids' => user.chapter_ids.sort
    }

    stub_google_auth(user) do
      stub_identity_platform do
        stub_cloudflare_images do
          delete '/me/account', headers: { 'Authorization': 'Bearer dummytoken' }
        end
      end
    end

    assert_response :ok
    body = response.parsed_body
    assert_equal expected, body.transform_values { |v| v.is_a?(Array) ? v.sort : v }
    assert_not_empty body['map_ids']
    assert_not_empty body['chapter_ids']
    assert_nil User.find_by(uid: user.uid)
  end

  test 'destroy without a token should be unauthorized' do
    delete '/me/account'

    assert_response :unauthorized
  end
end
