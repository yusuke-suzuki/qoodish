require 'test_helper'

class PinsControllerTest < ActionDispatch::IntegrationTest
  test 'get feeds should be success' do
    stub_google_auth(users(:me)) do
      get '/pins', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not res.empty?
    assert_not(res.any? do |pin|
                 pin['map']['id'] == maps(:private_unfollowing).id || pin['map']['id'] == maps(:public_unfollowing).id
               end)
  end

  test 'request to single pin on unfollowing private map should raise not found error' do
    stub_google_auth(users(:me)) do
      get "/pins/#{pins(:private_unfollowing).id}", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'request to single pin on following private map should be success' do
    stub_google_auth(users(:me)) do
      get "/pins/#{pins(:private_following).id}", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal pins(:private_following).id, res['id']
    assert_equal maps(:private_following).id, res['map']['id']
    assert res['map']['private']
  end

  test 'request to single pin on public map by another user should be success' do
    stub_google_auth(users(:you)) do
      get "/pins/#{pins(:public_one).id}", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)
    pin = pins(:public_one)

    assert_equal pin.id, res['id']
    assert_equal pin.name, res['name']
    assert_equal pin.comment, res['comment']
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

  test 'request to single pin without authentication should be unauthorized' do
    get "/pins/#{pins(:public_one).id}"

    assert_response :unauthorized
  end
end
