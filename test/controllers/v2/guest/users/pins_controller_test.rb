require 'test_helper'

class V2::Guest::Users::PinsControllerTest < ActionDispatch::IntegrationTest
  test 'index pages through the feed with the cursor it hands out' do
    publish_pins(PIN_FEED_PER_PAGE)

    pages = page_through("/guest/v2/users/#{users(:me).id}/pins")

    assert_operator pages.size, :>, 1
    assert_equal Pin.public_open.where(user: users(:me)).order(created_at: :desc, id: :desc).ids, pages.flatten
  end

  test 'index rejects a cursor it did not hand out' do
    get "/guest/v2/users/#{users(:me).id}/pins", params: { cursor: 'not-a-cursor' }

    assert_response :bad_request
  end
end
