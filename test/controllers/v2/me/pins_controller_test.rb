require 'test_helper'

class V2::Me::PinsControllerTest < ActionDispatch::IntegrationTest
  test 'index pages through the feed with the cursor it hands out' do
    publish_pins(PIN_FEED_PER_PAGE)

    pages = stub_google_auth(users(:me)) { page_through('/v2/me/pins', headers: { 'Authorization': 'Bearer dummytoken' }) }

    assert_operator pages.size, :>, 1
    assert_equal users(:me).pins.published.visible.order(created_at: :desc, id: :desc).ids, pages.flatten
  end

  test 'index returns own pins only' do
    stub_google_auth(users(:me)) do
      get '/v2/me/pins', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    data = JSON.parse(@response.body)['data']

    assert_not_empty data
    assert(data.all? { |pin| pin['author']['id'] == users(:me).id })
  end

  test 'index rejects a cursor it did not hand out' do
    stub_google_auth(users(:me)) do
      get '/v2/me/pins', params: { cursor: 'not-a-cursor' }, headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :bad_request
  end

  test 'index without a token should be unauthorized' do
    get '/v2/me/pins'

    assert_response :unauthorized
  end
end
