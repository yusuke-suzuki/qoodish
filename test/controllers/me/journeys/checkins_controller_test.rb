require 'test_helper'

class Me::Journeys::CheckinsControllerTest < ActionDispatch::IntegrationTest
  test 'check in on an in-progress journey should be success' do
    assert_difference 'JourneyCheckin.count', 1 do
      stub_google_auth(users(:me)) do
        post "/me/journeys/#{journeys(:my_in_progress).id}/checkins",
             params: { review_id: reviews(:private_you).id },
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal reviews(:private_you).id, res['review_id']
    assert_equal reviews(:private_you).name, res['spot']['name']
    assert_predicate res['checked_in_at'], :present?
  end

  test 'check in on an unstarted journey should raise unprocessable error' do
    stub_google_auth(users(:me)) do
      post "/me/journeys/#{journeys(:my_unstarted).id}/checkins",
           params: { review_id: reviews(:public_one).id },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
  end

  test 'check in at the same pin twice should raise unprocessable error' do
    stub_google_auth(users(:me)) do
      post "/me/journeys/#{journeys(:my_in_progress).id}/checkins",
           params: { review_id: reviews(:private).id },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
  end

  test 'check in on a journey of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      post "/me/journeys/#{journeys(:you_in_progress).id}/checkins",
           params: { review_id: reviews(:public_unfollowing).id },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'remove a checkin from an unfinished journey should be success' do
    assert_difference 'JourneyCheckin.count', -1 do
      stub_google_auth(users(:me)) do
        delete "/me/journeys/#{journeys(:my_in_progress).id}/checkins/#{journey_checkins(:my_in_progress_private).id}",
               headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
  end
end
