require 'test_helper'

class JournalsControllerTest < ActionDispatch::IntegrationTest
  test 'show a journal of another user should be success' do
    stub_google_auth(users(:me)) do
      get "/journals/#{journals(:you_journal).id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal journals(:you_journal).id, res['id']
    assert_not res['editable']
    assert res['bookmarking']
    assert_equal 4, res['chapters_count']
  end

  test 'show a journal without authentication should raise unauthorized error' do
    get "/journals/#{journals(:my_journal).id}"

    assert_response :unauthorized
  end
end
