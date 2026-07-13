require 'test_helper'

class Maps::JourneysControllerTest < ActionDispatch::IntegrationTest
  test 'create a journey on a referenceable map should be success' do
    assert_difference 'Journey.count', 1 do
      stub_google_auth(users(:you)) do
        post "/maps/#{maps(:public_two).id}/journeys",
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal maps(:public_two).id, res['map_id']
    assert_nil res['started_at']
    assert_empty res['milestones']
    assert_empty res['checkins']
    assert_nil res['encoded_path']
  end

  test 'create a journey on an unreferenceable private map should raise not found error' do
    stub_google_auth(users(:me)) do
      post "/maps/#{maps(:private_unfollowing).id}/journeys",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'create a second unfinished journey on the same map should raise unprocessable error' do
    stub_google_auth(users(:me)) do
      post "/maps/#{maps(:public_one).id}/journeys",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
  end

  test 'create a journey without authentication should raise unauthorized error' do
    post "/maps/#{maps(:public_one).id}/journeys"

    assert_response :unauthorized
  end
end
