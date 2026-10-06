require 'test_helper'

class V2::Guest::PinsControllerTest < ActionDispatch::IntegrationTest
  test 'index pages through the feed with the cursor it hands out' do
    publish_pins(PIN_FEED_PER_PAGE)

    pages = page_through('/guest/v2/pins')

    assert_operator pages.size, :>, 1
    assert_equal Pin.public_open.order(created_at: :desc, id: :desc).ids, pages.flatten
  end

  test 'index leaves out pins on private maps' do
    get '/guest/v2/pins'

    assert_response :success

    data = JSON.parse(@response.body)['data']

    assert_not_empty data
    assert(data.none? { |pin| pin['map']['private'] })
  end

  test 'index rejects a cursor it did not hand out' do
    get '/guest/v2/pins', params: { cursor: 'not-a-cursor' }

    assert_response :bad_request
  end
end
