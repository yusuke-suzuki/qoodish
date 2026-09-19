require 'test_helper'

class Guest::Maps::PinsControllerTest < ActionDispatch::IntegrationTest
  test 'list of pins on a private map should be empty' do
    get "/guest/maps/#{maps(:private).id}/pins"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_empty(res)
  end

  test 'list of pins on a public map should be success' do
    get "/guest/maps/#{maps(:public_one).id}/pins"

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |pin| pin['map']['id'] == maps(:public_one).id })
  end
end
