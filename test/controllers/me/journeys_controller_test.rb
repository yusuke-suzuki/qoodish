require 'test_helper'

class Me::JourneysControllerTest < ActionDispatch::IntegrationTest
  test 'index should return all own journeys with counts' do
    stub_google_auth(users(:me)) do
      get '/me/journeys',
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal 3, res.length

    in_progress = res.find { |journey| journey['id'] == journeys(:my_in_progress).id }

    assert_equal 1, in_progress['milestones_count']
    assert_equal 1, in_progress['checkins_count']
    assert_equal maps(:private).name, in_progress['map']['name']
  end

  test 'show own journey should return milestones, checkins and encoded path' do
    stub_google_auth(users(:me)) do
      get "/me/journeys/#{journeys(:my_in_progress).id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal journeys(:my_in_progress).id, res['id']
    assert_equal [reviews(:private).id], res['milestones'].map { |milestone| milestone['review_id'] }
    assert_equal [reviews(:private).id], res['checkins'].map { |checkin| checkin['review_id'] }
    assert_equal journeys(:my_in_progress).encoded_path, res['encoded_path']
    assert_equal maps(:private).name, res['map']['name']
  end

  test 'show journey of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      get "/me/journeys/#{journeys(:you_in_progress).id}",
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'start an unstarted journey should be success' do
    stub_google_auth(users(:me)) do
      post "/me/journeys/#{journeys(:my_unstarted).id}/start",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_predicate res['started_at'], :present?
    assert_nil res['finished_at']
  end

  test 'start a started journey should raise conflict error' do
    stub_google_auth(users(:me)) do
      post "/me/journeys/#{journeys(:my_in_progress).id}/start",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :conflict
  end

  test 'start a finished journey should raise not found error' do
    stub_google_auth(users(:me)) do
      post "/me/journeys/#{journeys(:my_finished).id}/start",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'finish a started journey should be success' do
    stub_google_auth(users(:me)) do
      post "/me/journeys/#{journeys(:my_in_progress).id}/finish",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_predicate res['finished_at'], :present?
  end

  test 'finish a started journey with an encoded path should store it' do
    stub_google_auth(users(:me)) do
      post "/me/journeys/#{journeys(:my_in_progress).id}/finish",
           params: { encoded_path: 'a~l~Fjk~uOwHJy@P' },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_predicate res['finished_at'], :present?
    assert_equal 'a~l~Fjk~uOwHJy@P', res['encoded_path']
  end

  test 'finish an unstarted journey should raise conflict error' do
    stub_google_auth(users(:me)) do
      post "/me/journeys/#{journeys(:my_unstarted).id}/finish",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :conflict
  end

  test 'destroy own journey should destroy its milestones' do
    assert_difference ['Journey.count', 'Milestone.count'], -1 do
      stub_google_auth(users(:me)) do
        delete "/me/journeys/#{journeys(:my_finished).id}",
               headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_nil chapters(:my_draft).reload.journey_id
  end

  test 'destroy journey of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      delete "/me/journeys/#{journeys(:you_in_progress).id}",
             headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end
end
