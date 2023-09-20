require 'test_helper'

class Guest::Maps::CollaboratorsControllerTest < ActionDispatch::IntegrationTest
  test 'list of collaborators on a private map should be empty' do
    get "/guest/maps/#{maps(:private).id}/collaborators"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_empty(res)
  end

  test 'list of collaborators on a public map should be success' do
    get "/guest/maps/#{maps(:public_one).id}/collaborators"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not_empty(res)
  end
end
