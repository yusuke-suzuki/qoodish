require 'test_helper'

class Me::PinsControllerTest < ActionDispatch::IntegrationTest
  test 'update own pin should be success' do
    stub_google_auth(users(:me)) do
      put "/me/pins/#{pins(:public_one).id}",
          params: { name: 'updated' },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal 'updated', res['name']
    assert_equal 'updated', pins(:public_one).reload.name
  end

  test 'update with image_ids attaches owned images' do
    image_a = users(:me).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/pin-update-a/public'
    )
    image_b = users(:me).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/pin-update-b/public'
    )

    stub_google_auth(users(:me)) do
      stub_cloudflare_images do
        put "/me/pins/#{pins(:public_one).id}",
            params: { name: 'updated', image_ids: [image_a.id, image_b.id] },
            headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_equal [image_a.id, image_b.id].sort,
                 pins(:public_one).reload.image_ids.sort
  end

  test 'update with image_ids keeps the images the earlier revision references' do
    pin = pins(:public_one)
    previous = pin.current_revision
    removed = images(:two)

    stub_google_auth(users(:me)) do
      stub_cloudflare_images do
        put "/me/pins/#{pin.id}",
            params: { image_ids: [images(:one).id] },
            headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_equal [images(:one).id], pin.reload.image_ids
    assert_includes previous.image_ids, removed.id
    assert Image.exists?(removed.id)
  end

  test 'update rejects image_ids that belong to another user' do
    foreign_image = users(:you).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/pin-foreign/public'
    )

    stub_google_auth(users(:me)) do
      stub_cloudflare_images do
        put "/me/pins/#{pins(:public_one).id}",
            params: { image_ids: [foreign_image.id] },
            headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :unprocessable_content
    assert_equal [images(:one).id, images(:two).id].sort,
                 pins(:public_one).reload.image_ids.sort
  end

  test 'update with property_option_ids replaces the options of the pin' do
    pin = pins(:public_one)

    stub_google_auth(users(:me)) do
      put "/me/pins/#{pin.id}",
          params: { property_option_ids: [pin_property_options(:cash_only).id, pin_property_options(:cafe).id] },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert_equal [pin_property_options(:cash_only).id, pin_property_options(:cafe).id].sort,
                 JSON.parse(@response.body)['property_option_ids'].sort
    assert_equal [pin_property_options(:cash_only).id, pin_property_options(:cafe).id].sort,
                 pin.reload.property_option_ids.sort
  end

  test 'update rejects property_option_ids offered on another map' do
    pin = pins(:public_one)

    stub_google_auth(users(:me)) do
      put "/me/pins/#{pin.id}",
          params: { property_option_ids: [pin_property_options(:other_map_ramen).id] },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :unprocessable_content
    assert_equal [pin_property_options(:paypay).id, pin_property_options(:ramen).id].sort,
                 pin.reload.property_option_ids.sort
  end

  test 'update a pin of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      put "/me/pins/#{pins(:public_you_one).id}",
          params: { name: 'hijacked' },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'destroy own pin marks it deleted without dropping the row' do
    pin = pins(:public_one)

    assert_no_difference 'Pin.count' do
      stub_google_auth(users(:me)) do
        delete "/me/pins/#{pin.id}", headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert_predicate pin.reload, :deleted?
  end

  test 'a deleted pin can no longer be read or revised' do
    pin = pins(:public_one)
    pin.discard!(user: users(:me))

    stub_google_auth(users(:me)) do
      put "/me/pins/#{pin.id}",
          params: { name: 'resurrected' },
          headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found

    stub_google_auth(users(:me)) do
      get "/pins/#{pin.id}", headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end

  test 'destroy a pin of another user should raise not found error' do
    stub_google_auth(users(:me)) do
      delete "/me/pins/#{pins(:public_you_one).id}",
             headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end
end
