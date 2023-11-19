require 'test_helper'

class Guest::Users::MapsControllerTest < ActionDispatch::IntegrationTest
  test 'list of user maps should not include private maps' do
    get "/guest/users/#{users(:me).id}/maps"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not_empty(res)

    assert(res.all? { |map| map['private'] == false })
  end
end
