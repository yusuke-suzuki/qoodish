require 'test_helper'

class Users::JournalsControllerTest < ActionDispatch::IntegrationTest
  test 'show should return the journal of the user' do
    stub_google_auth(users(:me)) do
      get "/users/#{users(:you).id}/journal",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal journals(:you_journal).id, res['id']
    assert_not res['editable']
  end

  test 'show with own uid should return own journal' do
    stub_google_auth(users(:me)) do
      get "/users/#{users(:me).uid}/journal",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal journals(:my_journal).id, res['id']
    assert res['editable']
  end

  test 'show without authentication should raise unauthorized error' do
    get "/users/#{users(:me).id}/journal"

    assert_response :unauthorized
  end
end
