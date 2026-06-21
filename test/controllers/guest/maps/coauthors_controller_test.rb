require 'test_helper'

class Guest::Maps::CoauthorsControllerTest < ActionDispatch::IntegrationTest
  test 'coauthors on a private map should be empty' do
    get "/guest/maps/#{maps(:private).id}/coauthors"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_empty(res)
  end

  test 'coauthors on a public map should include the author' do
    get "/guest/maps/#{maps(:public_one).id}/coauthors"

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.any? { |coauthor| coauthor['author'] })
  end
end
