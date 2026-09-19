require 'test_helper'

class Guest::Users::PinsControllerTest < ActionDispatch::IntegrationTest
  test 'list of user pins should not include pins on private maps' do
    get "/guest/users/#{users(:you).id}/pins"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not_empty(res)
    assert(res.all? { |pin| pin['author']['id'] == users(:you).id })
    assert(res.all? { |pin| pin['map']['private'] == false })
  end

  test 'list of user pins with next timestamp should not include pins on private maps' do
    next_timestamp = pins(:public_you_two).created_at.to_s
    get "/guest/users/#{users(:you).id}/pins?next_timestamp=#{next_timestamp}"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not_empty(res)
    assert(res.all? { |pin| pin['author']['id'] == users(:you).id })
    assert(res.all? { |pin| pin['map']['private'] == false })
  end
end
