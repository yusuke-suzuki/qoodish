require 'test_helper'

class V2::Users::PinsControllerTest < ActionDispatch::IntegrationTest
  test 'index pages through the feed with the cursor it hands out' do
    publish_pins(PIN_FEED_PER_PAGE)

    pages = stub_google_auth(users(:you)) { page_through("/v2/users/#{users(:me).id}/pins", headers: { 'Authorization': 'Bearer dummytoken' }) }

    assert_operator pages.size, :>, 1
    assert_equal users(:me).pins.referenceable_by(users(:you)).order(created_at: :desc, id: :desc).ids, pages.flatten
  end

  test 'index rejects a cursor it did not hand out' do
    stub_google_auth(users(:you)) do
      get "/v2/users/#{users(:me).id}/pins", params: { cursor: 'not-a-cursor' }, headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :bad_request
  end

  test 'index without a token should be unauthorized' do
    get "/v2/users/#{users(:me).id}/pins"

    assert_response :unauthorized
  end
end
