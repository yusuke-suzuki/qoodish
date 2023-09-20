require 'test_helper'

class Guest::Users::ReviewsControllerTest < ActionDispatch::IntegrationTest
  test 'list of user reviews should not include reviews on private maps' do
    get "/guest/users/#{users(:you).id}/reviews"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not_empty(res)
    assert(res.all? { |review| review['author']['id'] == users(:you).id })
    assert(res.all? { |review| review['map']['private'] == false })
  end

  test 'list of user reviews with next timestamp should not include reviews on private maps' do
    next_timestamp = reviews(:public_you_two).created_at.to_s
    get "/guest/users/#{users(:you).id}/reviews?next_timestamp=#{next_timestamp}"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not_empty(res)
    assert(res.all? { |review| review['author']['id'] == users(:you).id })
    assert(res.all? { |review| review['map']['private'] == false })
  end
end
