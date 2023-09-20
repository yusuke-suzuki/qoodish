require 'test_helper'

class Guest::Maps::SpotsControllerTest < ActionDispatch::IntegrationTest
  test 'list of spots on a private map should be empty' do
    get "/guest/maps/#{maps(:private).id}/spots"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_empty(res)
  end

  test 'list of spots on a public map should be success' do
    get "/guest/maps/#{maps(:public_one).id}/spots"

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |spot| spot['map_id'] == maps(:public_one).id })
  end

  test 'request to single spot on private map should raise not found error' do
    get "/guest/maps/#{maps(:private).id}/spots/#{spots(:private_one).id}"

    assert_response :not_found
  end

  test 'request to single spot on public map should be success' do
    get "/guest/maps/#{maps(:public_one).id}/spots/#{spots(:public_one).id}"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal res['id'], spots(:public_one).id
  end
end
