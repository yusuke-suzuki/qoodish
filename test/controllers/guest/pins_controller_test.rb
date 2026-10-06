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

  test 'show tells a guest how many likes the pin holds' do
    pin = pins(:public_two)

    get "/guest/pins/#{pin.id}"

    assert_equal pin.votes.count, JSON.parse(@response.body)['likes_count']

    users(:me).liked!(pin)

    get "/guest/pins/#{pin.id}"

    assert_equal pin.votes.count, JSON.parse(@response.body)['likes_count']
  end

  test 'show does not tell a guest whether the pin was liked' do
    users(:me).liked!(pins(:public_one))

    get "/guest/pins/#{pins(:public_one).id}"

    assert_not_includes JSON.parse(@response.body).keys, 'liked'
  end

  test 'request pins without params should raise bad request error' do
    get '/guest/pins'

    assert_response :bad_request
  end

  test 'list of pins by input should find pins by name or comment' do
    get '/guest/pins', params: { input: '醤油 broth' }

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal [pins(:ramen_alley).id], res.map { |pin| pin['id'] }
  end

  test 'list of pins by input should not include pins on private maps' do
    get '/guest/pins', params: { input: 'name' }

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not res.empty?
    assert(res.all? { |pin| pin['map']['private'] == false })
  end

  test 'list of recent pins should not include pins on private maps' do
    get '/guest/pins?recent=true'

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |pin| pin['map']['private'] == false })
  end

  test 'list of popular pins should not include pins on private maps' do
    get '/guest/pins?popular=true'

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |pin| pin['map']['private'] == false })
  end
end
