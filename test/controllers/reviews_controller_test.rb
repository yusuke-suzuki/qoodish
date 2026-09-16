require 'test_helper'

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  test 'get feeds should be success' do
    stub_google_auth(users(:me)) do
      get '/reviews', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not res.empty?
    assert_not(res.any? do |review|
                 review['map']['id'] == maps(:private_unfollowing).id || review['map']['id'] == maps(:public_unfollowing).id
               end)
  end

  test 'request to single review on unfollowing private map should raise not found error' do
    stub_google_auth(users(:me)) do
      get "/reviews/#{reviews(:private_unfollowing).id}", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'request to single review on following private map should be success' do
    stub_google_auth(users(:me)) do
      get "/reviews/#{reviews(:private_following).id}", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal reviews(:private_following).id, res['id']
    assert_equal maps(:private_following).id, res['map']['id']
    assert res['map']['private']
  end

  test 'request to single review on public map by another user should be success' do
    stub_google_auth(users(:you)) do
      get "/reviews/#{reviews(:public_one).id}", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)
    review = reviews(:public_one)

    assert_equal review.id, res['id']
    assert_equal review.name, res['name']
    assert_equal review.comment, res['comment']
    assert_equal users(:me).id, res['author']['id']
    assert_equal maps(:public_one).id, res['map']['id']
    assert_equal maps(:public_one).name, res['map']['name']
    assert_not res['map']['private']
    assert_not res['editable']
    assert_kind_of Array, res['comments']
    assert_kind_of Array, res['images']
    assert_kind_of Integer, res['likes_count']
    assert res.key?('liked')
    assert res.key?('created_at')
    assert res.key?('updated_at')
  end

  test 'request to single review without authentication should be unauthorized' do
    get "/reviews/#{reviews(:public_one).id}"

    assert_response :unauthorized
  end
end
