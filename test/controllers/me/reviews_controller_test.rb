require 'test_helper'

class Me::ReviewsControllerTest < ActionDispatch::IntegrationTest
  test 'index should return own reviews only' do
    stub_google_auth(users(:me)) do
      get '/me/reviews', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not res.empty?
    assert_equal users(:me).reviews.pluck(:id).sort,
                 res.map { |review| review['id'] }.sort
  end

  test 'index with next_timestamp should return only older reviews' do
    newer = reviews(:public_one)
    older = reviews(:public_two)
    newer.update_columns(created_at: Time.zone.parse('2021-02-01 00:00:00'))
    older.update_columns(created_at: Time.zone.parse('2021-01-01 00:00:00'))

    stub_google_auth(users(:me)) do
      get '/me/reviews',
          params: { next_timestamp: newer.created_at.iso8601 },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)
    ids = res.map { |review| review['id'] }

    assert_includes ids, older.id
    assert_not_includes ids, newer.id
    assert_equal users(:me).reviews.where(created_at: ...newer.created_at).pluck(:id).sort,
                 ids.sort
  end

  test 'update own review should be success' do
    stub_google_auth(users(:me)) do
      put "/me/reviews/#{reviews(:public_one).id}",
          params: { name: 'updated' },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal 'updated', res['name']
    assert_equal 'updated', reviews(:public_one).reload.name
  end

  test 'update with image_ids attaches owned images' do
    image_a = users(:me).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/review-update-a/public'
    )
    image_b = users(:me).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/review-update-b/public'
    )

    stub_google_auth(users(:me)) do
      stub_cloudflare_images do
        put "/me/reviews/#{reviews(:public_one).id}",
            params: { name: 'updated', image_ids: [image_a.id, image_b.id] },
            headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_equal [image_a.id, image_b.id].sort,
                 reviews(:public_one).reload.image_ids.sort
  end

  test 'update with image_ids destroys removed images' do
    review = reviews(:public_one)
    removed = images(:two)

    stub_google_auth(users(:me)) do
      stub_cloudflare_images do
        put "/me/reviews/#{review.id}",
            params: { image_ids: [images(:one).id] },
            headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_equal [images(:one).id], review.reload.image_ids
    assert_nil Image.find_by(id: removed.id)
  end

  test 'update rejects image_ids that belong to another user' do
    foreign_image = users(:you).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/review-foreign/public'
    )

    stub_google_auth(users(:me)) do
      stub_cloudflare_images do
        put "/me/reviews/#{reviews(:public_one).id}",
            params: { image_ids: [foreign_image.id] },
            headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :unprocessable_content
    assert_equal [images(:one).id, images(:two).id].sort,
                 reviews(:public_one).reload.image_ids.sort
  end

  test 'update a review of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      put "/me/reviews/#{reviews(:public_you_one).id}",
          params: { name: 'hijacked' },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'destroy own review should be success' do
    assert_difference 'Review.count', -1 do
      stub_google_auth(users(:me)) do
        stub_cloudflare_images do
          delete "/me/reviews/#{reviews(:public_one).id}",
                 headers: { 'Authorization': 'Bearer dummytoken' }
        end
      end
    end

    assert_response :success
  end

  test 'destroy a review of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      delete "/me/reviews/#{reviews(:public_you_one).id}",
             headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end
end
