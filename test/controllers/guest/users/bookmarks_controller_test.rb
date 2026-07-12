require 'test_helper'

class Guest::Users::BookmarksControllerTest < ActionDispatch::IntegrationTest
  test 'list of user bookmarks returns public bookmarked maps' do
    get "/guest/users/#{users(:you).id}/bookmarks"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_includes res.map { |map| map['id'] }, maps(:public_one).id
    assert(res.all? { |map| map['private'] == false })
  end
end
