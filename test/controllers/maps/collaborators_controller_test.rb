require 'test_helper'

class Maps::CollaboratorsControllerTest < ActionDispatch::IntegrationTest
  test 'list of collaborators on a unfollowing private map should be empty' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:private_unfollowing).id}/collaborators", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_empty(res)
  end

  test 'list of collaborators on a following private map should be success' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:private_following).id}/collaborators", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.any? { |collaborator| collaborator['id'] == users(:me).id })
  end

  test 'list of collaborators on a public map should be success' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:public_one).id}/collaborators", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.any? { |collaborator| collaborator['id'] == users(:me).id })
  end
end
