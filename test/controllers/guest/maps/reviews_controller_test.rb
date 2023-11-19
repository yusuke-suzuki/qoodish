require 'test_helper'

class Guest::Maps::ReviewsControllerTest < ActionDispatch::IntegrationTest
  test 'list of reviews on a private map should be empty' do
    get "/guest/maps/#{maps(:private).id}/reviews"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_empty(res)
  end

  test 'list of reviews on a public map should be success' do
    get "/guest/maps/#{maps(:public_one).id}/reviews"

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |review| review['map']['id'] == maps(:public_one).id })
  end
end
