require 'test_helper'

class Me::Bookmarks::JournalsControllerTest < ActionDispatch::IntegrationTest
  test 'index should return bookmarked journals' do
    stub_google_auth(users(:me)) do
      get '/me/bookmarks/journals',
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal [journals(:you_journal).id], res.map { |journal| journal['id'] }
    assert res.first['bookmarking']
  end

  test 'index without any bookmark should return an empty array' do
    stub_google_auth(users(:you)) do
      get '/me/bookmarks/journals',
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    assert_empty JSON.parse(@response.body)
  end

  test 'index without authentication should raise unauthorized error' do
    get '/me/bookmarks/journals'

    assert_response :unauthorized
  end
end
