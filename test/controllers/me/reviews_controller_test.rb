require 'test_helper'

class Me::ReviewsControllerTest < ActionDispatch::IntegrationTest
  test 'index should return own reviews only' do
    stub_google_auth(users(:me)) do
      get '/me/reviews', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not res.empty?
    assert_equal users(:me).reviews.pluck(:id).sort,
                 res.map { |review| review['id'] }.sort
  end

  test 'index with next_timestamp should return only older reviews' do
    newer = reviews(:public_one)
    older = reviews(:public_two)
    newer.update_columns(created_at: Time.zone.parse('2021-02-01 00:00:00'))
    older.update_columns(created_at: Time.zone.parse('2021-01-01 00:00:00'))

    stub_google_auth(users(:me)) do
      get '/me/reviews',
          params: { next_timestamp: newer.created_at.iso8601 },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)
    ids = res.map { |review| review['id'] }

    assert_includes ids, older.id
    assert_not_includes ids, newer.id
    assert_equal users(:me).reviews.where(created_at: ...newer.created_at).pluck(:id).sort,
                 ids.sort
  end

  test 'update own review should be success' do
    stub_google_auth(users(:me)) do
      put "/me/reviews/#{reviews(:public_one).id}",
          params: { name: 'updated' },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal 'updated', res['name']
    assert_equal 'updated', reviews(:public_one).reload.name
  end

  test 'update a review of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      put "/me/reviews/#{reviews(:public_you_one).id}",
          params: { name: 'hijacked' },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'destroy own review should be success' do
    assert_difference 'Review.count', -1 do
      stub_google_auth(users(:me)) do
        stub_cloudflare_images do
          delete "/me/reviews/#{reviews(:public_one).id}",
                 headers: { 'Authorization': 'Bearer dummytoken' }
        end
      end
    end

    assert_response :success
  end

  test 'destroy a review of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      delete "/me/reviews/#{reviews(:public_you_one).id}",
             headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end
end
