require 'test_helper'

class Guest::UsersControllerTest < ActionDispatch::IntegrationTest
  test 'request to show a user should be success' do
    get "/guest/users/#{users(:me).id}"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal(res['id'], users(:me).id)
  end
end
