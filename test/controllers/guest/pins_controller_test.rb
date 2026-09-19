require 'test_helper'

class Guest::PinsControllerTest < ActionDispatch::IntegrationTest
  test 'request to single pin on private map should raise not found error' do
    get "/guest/pins/#{pins(:private).id}"

    assert_response :not_found
  end

  test 'request to single pin on public map should be success' do
    get "/guest/pins/#{pins(:public_one).id}"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal res['id'], pins(:public_one).id
  end

  test 'request pins without params should raise bad request error' do
    get '/guest/pins'

    assert_response :bad_request
  end

  test 'list of recent pins should not include pins on private maps' do
    get '/guest/pins?recent=true'

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |pin| pin['map']['private'] == false })
  end

  test 'feed of pins should not include pins on private maps' do
    get '/guest/pins?feed=true'

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not res.empty?
    assert(res.all? { |pin| pin['map']['private'] == false })
  end

  test 'feed of pins should page with next_timestamp' do
    get '/guest/pins?feed=true'

    first_page = JSON.parse(@response.body)
    newest = first_page.first

    get '/guest/pins', params: { feed: true, next_timestamp: newest['created_at'] }

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not_includes res.map { |pin| pin['id'] }, newest['id']
    assert(res.all? { |pin| Time.parse(pin['created_at']) < Time.parse(newest['created_at']) })
  end

  test 'feed of pins should continue past rows sharing a timestamp' do
    get '/guest/pins?feed=true'

    first_page = JSON.parse(@response.body)
    newest = first_page.first

    get '/guest/pins', params: { feed: true, next_timestamp: newest['created_at'], next_id: newest['id'] }

    assert_response :success

    res = JSON.parse(@response.body)
    ids = res.map { |pin| pin['id'] }

    assert_not_includes ids, newest['id']
    assert_equal first_page.drop(1).map { |pin| pin['id'] }.first(res.size), ids.first(res.size)
  end

  test 'feed of pins should reject a malformed cursor' do
    get '/guest/pins', params: { feed: true, next_timestamp: 'not-a-time' }

    assert_response :bad_request
  end

  test 'list of popular pins should not include pins on private maps' do
    get '/guest/pins?popular=true'

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |pin| pin['map']['private'] == false })
  end
end
