require 'test_helper'

class Users::ChaptersControllerTest < ActionDispatch::IntegrationTest
  test 'index of another user returns published chapters on referenceable maps only' do
    stub_google_auth(users(:me)) do
      get "/users/#{users(:you).id}/chapters",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)
    ids = res.map { |chapter| chapter['id'] }

    assert_includes ids, chapters(:you_published).id
    assert_includes ids, chapters(:you_private_published_following).id
    assert_not_includes ids, chapters(:you_private_published_unfollowing).id
    assert_not_includes ids, chapters(:you_draft).id
  end

  test 'index with own uid should return only published chapters' do
    stub_google_auth(users(:me)) do
      get "/users/#{users(:me).uid}/chapters",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal [chapters(:my_published).id], res.map { |chapter| chapter['id'] }
  end
end
