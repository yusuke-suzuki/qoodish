require 'test_helper'

class Guest::MapsControllerTest < ActionDispatch::IntegrationTest
  test 'request to single private map should raise not found error' do
    get "/guest/maps/#{maps(:private).id}"

    assert_response :not_found
  end

  test 'request to single public map should be success' do
    get "/guest/maps/#{maps(:public_one).id}"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal res['id'], maps(:public_one).id
  end

  test 'request maps without params should raise bad request error' do
    get '/guest/maps'

    assert_response :bad_request
  end

  test 'list of maps by input should not include private maps' do
    get "/guest/maps?input=#{maps(:private).name}"

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |map| map['private'] == false })
  end

  test 'list of maps by input should be success' do
    get "/guest/maps?input=#{maps(:public_one).name}"

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.any? { |map| map['id'] == maps(:public_one).id })
  end

  test 'list of recent maps should not include private maps' do
    get '/guest/maps?recent=true'

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |map| map['private'] == false })
  end

  test 'list of active maps should not include private maps' do
    get '/guest/maps?active=true'

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |map| map['private'] == false })
  end

  test 'list of popular maps should not include private maps' do
    get '/guest/maps?popular=true'

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |map| map['private'] == false })
  end

  test 'list of recommend maps should not include private maps' do
    get '/guest/maps?recommend=true'

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.all? { |map| map['private'] == false })
  end
end
