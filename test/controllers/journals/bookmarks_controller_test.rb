require 'test_helper'

class Journals::BookmarksControllerTest < ActionDispatch::IntegrationTest
  test 'bookmark a journal of another user should be success' do
    assert_difference 'JournalBookmark.count', 1 do
      assert_no_difference 'Notification.count' do
        stub_google_auth(users(:you)) do
          post "/journals/#{journals(:my_journal).id}/bookmark",
               headers: { 'Authorization': 'Bearer dummytoken' }
        end
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert res['bookmarking']
  end

  test 'bookmark own journal should be forbidden' do
    stub_google_auth(users(:me)) do
      post "/journals/#{journals(:my_journal).id}/bookmark",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :forbidden
  end

  test 'bookmark an already bookmarked journal should be unprocessable' do
    stub_google_auth(users(:me)) do
      post "/journals/#{journals(:you_journal).id}/bookmark",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
  end

  test 'unbookmark a bookmarked journal should be success' do
    assert_difference 'JournalBookmark.count', -1 do
      stub_google_auth(users(:me)) do
        delete "/journals/#{journals(:you_journal).id}/bookmark",
               headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not res['bookmarking']
  end

  test 'unbookmark a journal without an existing bookmark should raise not found error' do
    stub_google_auth(users(:you)) do
      delete "/journals/#{journals(:my_journal).id}/bookmark",
             headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'bookmark a journal without authentication should raise unauthorized error' do
    post "/journals/#{journals(:my_journal).id}/bookmark"

    assert_response :unauthorized
  end
end
