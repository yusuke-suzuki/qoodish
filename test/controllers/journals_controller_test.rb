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
    assert_equal 3, res['chapters_count']
  end

  test 'update own journal should be success' do
    stub_google_auth(users(:me)) do
      put "/journals/#{journals(:my_journal).id}",
          params: { title: 'Renamed journal' },
          headers: { 'Authorization': 'Bearer dummytoken' },
          as: :json
    end

    assert_response :success

    assert_equal 'Renamed journal', journals(:my_journal).reload.title
  end

  test 'update a journal without a title should raise unprocessable error' do
    stub_google_auth(users(:me)) do
      put "/journals/#{journals(:my_journal).id}",
          params: { title: '' },
          headers: { 'Authorization': 'Bearer dummytoken' },
          as: :json
    end

    assert_response :unprocessable_content
  end

  test 'update a journal of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      put "/journals/#{journals(:you_journal).id}",
          params: { title: 'Hijacked' },
          headers: { 'Authorization': 'Bearer dummytoken' },
          as: :json
    end

    assert_response :not_found
  end

  test 'show a journal without authentication should raise unauthorized error' do
    get "/journals/#{journals(:my_journal).id}"

    assert_response :unauthorized
  end
end
