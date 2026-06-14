require 'test_helper'

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  test 'get feeds should be success' do
    stub_google_auth(users(:me)) do
      get '/reviews', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_not res.empty?
    assert_not(res.any? do |review|
                 review['map']['id'] == maps(:private_unfollowing).id || review['map']['id'] == maps(:public_unfollowing).id
               end)
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
        put "/reviews/#{reviews(:public_one).id}",
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
        put "/reviews/#{review.id}",
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
        put "/reviews/#{reviews(:public_one).id}",
            params: { image_ids: [foreign_image.id] },
            headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :unprocessable_content
    assert_equal [images(:one).id, images(:two).id].sort,
                 reviews(:public_one).reload.image_ids.sort
  end
end
