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

  test 'feed of reviews should not include reviews on private maps' do
    get '/guest/reviews?feed=true'

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not res.empty?
    assert(res.all? { |review| review['map']['private'] == false })
  end

  test 'feed of reviews should page with next_timestamp' do
    get '/guest/reviews?feed=true'

    first_page = JSON.parse(@response.body)
    newest = first_page.first

    get '/guest/reviews', params: { feed: true, next_timestamp: newest['created_at'] }

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not_includes res.map { |review| review['id'] }, newest['id']
    assert(res.all? { |review| Time.parse(review['created_at']) < Time.parse(newest['created_at']) })
  end

  test 'list of popular reviews should not include reviews on private maps' do
    get '/guest/reviews?popular=true'

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |review| review['map']['private'] == false })
  end
end
