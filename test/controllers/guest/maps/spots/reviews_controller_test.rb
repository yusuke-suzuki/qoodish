require 'test_helper'

class Guest::Maps::Spots::ReviewsControllerTest < ActionDispatch::IntegrationTest
  test 'list of reviews for a private spot should be empty' do
    get "/guest/maps/#{maps(:private).id}/spots/#{spots(:private_one).id}/reviews"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_empty(res)
  end

  test 'list of reviews for a public spot should be success' do
    get "/guest/maps/#{maps(:public_one).id}/spots/#{spots(:public_one).id}/reviews"

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |review| review['map']['id'] == maps(:public_one).id })
  end
end
