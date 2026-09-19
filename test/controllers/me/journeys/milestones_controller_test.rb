require 'test_helper'

class Me::Journeys::MilestonesControllerTest < ActionDispatch::IntegrationTest
  test 'add a milestone to an unstarted journey should be success' do
    assert_difference 'Milestone.count', 1 do
      stub_google_auth(users(:me)) do
        post "/me/journeys/#{journeys(:my_unstarted).id}/milestones",
             params: { pin_id: pins(:public_one).id },
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal pins(:public_one).id, res['pin_id']
    assert_equal pins(:public_one).name, res['name']
  end

  test 'add a milestone to an in-progress journey should be success' do
    assert_difference 'Milestone.count', 1 do
      stub_google_auth(users(:me)) do
        post "/me/journeys/#{journeys(:my_in_progress).id}/milestones",
             params: { pin_id: pins(:private_you).id },
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
  end

  test 'add the same pin twice should raise unprocessable error' do
    stub_google_auth(users(:me)) do
      post "/me/journeys/#{journeys(:my_in_progress).id}/milestones",
           params: { pin_id: pins(:private).id },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
  end

  test 'add a pin on another map should raise unprocessable error' do
    stub_google_auth(users(:me)) do
      post "/me/journeys/#{journeys(:my_unstarted).id}/milestones",
           params: { pin_id: pins(:private).id },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
  end

  test 'add a milestone to a finished journey should raise not found error' do
    stub_google_auth(users(:me)) do
      post "/me/journeys/#{journeys(:my_finished).id}/milestones",
           params: { pin_id: pins(:public_two).id },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'add a milestone to a journey of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      post "/me/journeys/#{journeys(:you_in_progress).id}/milestones",
           params: { pin_id: pins(:public_unfollowing).id },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'remove a milestone from an unfinished journey should be success' do
    assert_difference 'Milestone.count', -1 do
      stub_google_auth(users(:me)) do
        delete "/me/journeys/#{journeys(:my_in_progress).id}/milestones/#{milestones(:my_in_progress_first).id}",
               headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
  end

  test 'remove a milestone from a finished journey should raise not found error' do
    stub_google_auth(users(:me)) do
      delete "/me/journeys/#{journeys(:my_finished).id}/milestones/#{milestones(:my_finished_first).id}",
             headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end
end
