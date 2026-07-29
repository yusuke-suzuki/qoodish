require 'test_helper'

class Me::JournalsControllerTest < ActionDispatch::IntegrationTest
  test 'show should return own journal' do
    stub_google_auth(users(:me)) do
      get '/me/journal', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal journals(:my_journal).id, res['id']
    assert res['editable']
  end

  test 'update own journal should be success' do
    stub_google_auth(users(:me)) do
      put '/me/journal',
          params: { title: 'Renamed journal' },
          headers: { 'Authorization': 'Bearer dummytoken' },
          as: :json
    end

    assert_response :success

    assert_equal 'Renamed journal', journals(:my_journal).reload.title
  end

  test 'update without a title should raise unprocessable error' do
    stub_google_auth(users(:me)) do
      put '/me/journal',
          params: { title: '' },
          headers: { 'Authorization': 'Bearer dummytoken' },
          as: :json
    end

    assert_response :unprocessable_content
  end

  test 'show without a token should be unauthorized' do
    get '/me/journal'

    assert_response :unauthorized
  end
end
