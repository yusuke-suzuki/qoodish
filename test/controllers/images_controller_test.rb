require 'test_helper'

class ImagesControllerTest < ActionDispatch::IntegrationTest
  test 'create without authentication should return unauthorized' do
    post '/images'
    assert_response :unauthorized
  end

  test 'create with authentication should return upload URL and image id' do
    stub_google_auth(users(:me)) do
      stub_cloudflare_images do
        post '/images', headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)
    assert res['id'].present?
    assert_equal 'https://upload.example.com/qoodish/test/mock-cf-id', res['upload_url']

    image = Image.find(res['id'])
    assert_equal users(:me).id, image.user_id
    assert_nil image.imageable_id
    assert_equal 'https://imagedelivery.net/mockhash/qoodish/test/mock-cf-id/public', image.url
  end
end
