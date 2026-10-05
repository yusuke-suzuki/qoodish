require 'test_helper'

class V2::PinsControllerTest < ActionDispatch::IntegrationTest
  test 'index pages through the feed with the cursor it hands out' do
    publish_pins(PIN_FEED_PER_PAGE)

    pages = stub_google_auth(users(:me)) { page_through('/v2/pins', headers: { 'Authorization': 'Bearer dummytoken' }) }

    assert_operator pages.size, :>, 1
    assert_equal Pin.feed_for(users(:me)).order(created_at: :desc, id: :desc).ids, pages.flatten
  end

  test 'index rejects a cursor it did not hand out' do
    stub_google_auth(users(:me)) do
      get '/v2/pins', params: { cursor: 'not-a-cursor' }, headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :bad_request
  end

  test 'index without a token should be unauthorized' do
    get '/v2/pins'

    assert_response :unauthorized
  end
end
