require 'test_helper'

class Maps::CoauthorsControllerTest < ActionDispatch::IntegrationTest
  test 'coauthors on a non-referenceable private map should be empty' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:private_unfollowing).id}/coauthors", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_empty(res)
  end

  test 'coauthors on a coauthored private map include the current user' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:private_following).id}/coauthors", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.any? { |coauthor| coauthor['id'] == users(:me).id })
  end

  test 'coauthors on a public map include the author' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:public_one).id}/coauthors", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    author = res.find { |coauthor| coauthor['id'] == users(:me).id }

    assert author
    assert author['author']
  end

  test 'author can remove a coauthor' do
    stub_google_auth(users(:me)) do
      delete "/maps/#{maps(:private).id}/coauthors/#{users(:you).id}",
             headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert_not Coauthorship.exists?(map: maps(:private), user: users(:you))
  end

  test 'non-author cannot remove a coauthor' do
    stub_google_auth(users(:me)) do
      delete "/maps/#{maps(:private_unfollowing).id}/coauthors/#{users(:you).id}",
             headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end
end
