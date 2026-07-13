require 'test_helper'

class Guest::Users::ChaptersControllerTest < ActionDispatch::IntegrationTest
  test 'index should return only published chapters' do
    get "/guest/users/#{users(:me).id}/chapters"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal [chapters(:my_published).id], res.map { |chapter| chapter['id'] }
  end

  test 'index should exclude published chapters on private maps' do
    get "/guest/users/#{users(:you).id}/chapters"

    assert_response :success

    res = JSON.parse(@response.body)
    ids = res.map { |chapter| chapter['id'] }

    assert_includes ids, chapters(:you_published).id
    assert_not_includes ids, chapters(:you_private_published_following).id
    assert_not_includes ids, chapters(:you_private_published_unfollowing).id
  end
end
