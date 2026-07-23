require 'test_helper'

class ChaptersControllerTest < ActionDispatch::IntegrationTest
  test 'index should return published chapters on maps related to the user' do
    stub_google_auth(users(:me)) do
      get '/chapters',
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)
    ids = res.map { |chapter| chapter['id'] }

    assert_includes ids, chapters(:my_published).id
    assert_includes ids, chapters(:you_private_published_following).id
    assert_not_includes ids, chapters(:you_published).id
    assert_not_includes ids, chapters(:you_private_published_unfollowing).id
    assert_not_includes ids, chapters(:my_draft).id
    assert_not_includes ids, chapters(:you_draft).id
  end

  test 'index with next_timestamp should return only older chapters' do
    stub_google_auth(users(:me)) do
      get '/chapters',
          params: { next_timestamp: '2026-06-08T00:00:00Z' },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal [chapters(:my_published).id], res.map { |chapter| chapter['id'] }
  end

  test 'show a published chapter of another user returns the content verbatim' do
    stub_google_auth(users(:you)) do
      get "/chapters/#{chapters(:my_published).id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not res['editable']
    assert_equal chapters(:my_published).content['root'], res['content']['root']
    assert_equal users(:me).biography, res['author']['biography']
    assert_equal journals(:my_journal).title, res['journal']['title']
  end

  test 'show a published chapter on a private map as a coauthor should be success' do
    stub_google_auth(users(:me)) do
      get "/chapters/#{chapters(:you_private_published_following).id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal chapters(:you_private_published_following).id, res['id']
    assert_not res['editable']
  end

  test 'show a published chapter on an unreferenceable private map should raise not found error' do
    stub_google_auth(users(:me)) do
      get "/chapters/#{chapters(:you_private_published_unfollowing).id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'show a draft chapter of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      get "/chapters/#{chapters(:you_draft).id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'show own draft chapter should be success' do
    stub_google_auth(users(:me)) do
      get "/chapters/#{chapters(:my_draft).id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert res['editable']
  end

  test 'show a chapter without authentication should raise unauthorized error' do
    get "/chapters/#{chapters(:my_published).id}"

    assert_response :unauthorized
  end
end
