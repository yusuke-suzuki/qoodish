require 'test_helper'

class Guest::ReviewsControllerTest < ActionDispatch::IntegrationTest
  test 'request to single review on private map should raise not found error' do
    get "/guest/reviews/#{reviews(:private).id}"

    assert_response :not_found
  end

  test 'request to single review on public map should be success' do
    get "/guest/reviews/#{reviews(:public_one).id}"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal res['id'], reviews(:public_one).id
  end

  test 'request reviews without params should raise bad request error' do
    get '/guest/reviews'

    assert_response :bad_request
  end

  test 'list of recent reviews should not include reviews on private maps' do
    get '/guest/reviews?recent=true'

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |review| review['map']['private'] == false })
  end

  test 'list of popular reviews should not include reviews on private maps' do
    get '/guest/reviews?popular=true'

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |review| review['map']['private'] == false })
  end
end
