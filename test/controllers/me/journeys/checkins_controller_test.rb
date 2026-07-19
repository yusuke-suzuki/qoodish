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

  test 'check in with image_ids attaches owned images' do
    image = users(:me).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/checkin-create/public'
    )

    stub_google_auth(users(:me)) do
      post "/me/journeys/#{journeys(:my_in_progress).id}/checkins",
           params: { review_id: reviews(:private_you).id, image_ids: [image.id] },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal [image.id], res['images'].map { |i| i['id'] }
    assert_equal [image.id], JourneyCheckin.find(res['id']).image_ids
  end

  test 'check in with too many image_ids should raise unprocessable error' do
    image_ids = Array.new(5) do |i|
      users(:me).owned_images.create!(
        url: "https://imagedelivery.net/mockhash/checkin-limit-#{i}/public"
      ).id
    end

    assert_no_difference 'JourneyCheckin.count' do
      stub_google_auth(users(:me)) do
        post "/me/journeys/#{journeys(:my_in_progress).id}/checkins",
             params: { review_id: reviews(:private_you).id, image_ids: image_ids },
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :unprocessable_content
  end

  test 'update with image_ids attaches images to a finished journey checkin' do
    image = users(:me).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/checkin-update/public'
    )
    checkin = journey_checkins(:my_finished_public_one)

    stub_google_auth(users(:me)) do
      put "/me/journeys/#{journeys(:my_finished).id}/checkins/#{checkin.id}",
          params: { image_ids: [image.id] },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert_equal [image.id], checkin.reload.image_ids

    res = JSON.parse(@response.body)

    assert_equal [image.id], res['images'].map { |i| i['id'] }
  end

  test 'update with image_ids destroys removed images' do
    checkin = journey_checkins(:my_finished_public_one)
    kept = checkin.images.create!(
      user: users(:me),
      url: 'https://imagedelivery.net/mockhash/checkin-kept/public'
    )
    removed = checkin.images.create!(
      user: users(:me),
      url: 'https://imagedelivery.net/mockhash/checkin-removed/public'
    )

    stub_google_auth(users(:me)) do
      stub_cloudflare_images do
        put "/me/journeys/#{journeys(:my_finished).id}/checkins/#{checkin.id}",
            params: { image_ids: [kept.id] },
            headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_equal [kept.id], checkin.reload.image_ids
    assert_nil Image.find_by(id: removed.id)
  end

  test 'update rejects image_ids that belong to another user' do
    foreign_image = users(:you).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/checkin-foreign/public'
    )
    checkin = journey_checkins(:my_finished_public_one)

    stub_google_auth(users(:me)) do
      put "/me/journeys/#{journeys(:my_finished).id}/checkins/#{checkin.id}",
          params: { image_ids: [foreign_image.id] },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
    assert_empty checkin.reload.image_ids
  end

  test 'update a checkin on a journey of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      put "/me/journeys/#{journeys(:you_in_progress).id}/checkins/#{journey_checkins(:my_finished_public_one).id}",
          params: { image_ids: [] },
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
