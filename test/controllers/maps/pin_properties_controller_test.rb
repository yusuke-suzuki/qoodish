require 'test_helper'

class Maps::PinPropertiesControllerTest < ActionDispatch::IntegrationTest
  test 'index lists the published properties of a map with their published options' do
    pin_properties(:genre).discard!(user: users(:me))
    pin_property_options(:cash_only).discard!(user: users(:me))

    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:public_one).id}/pin_properties", headers: authorization
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal [pin_properties(:payment).id], res.pluck('id')
    assert_equal [pin_property_options(:paypay).id], res.first['options'].pluck('id')
    assert res.first['multiple']
  end

  test 'index on a map the user cannot read is not found' do
    stub_google_auth(users(:me)) do
      get "/maps/#{maps(:private_unfollowing).id}/pin_properties", headers: authorization
    end

    assert_response :not_found
  end

  test 'create defines a property on a map the user owns' do
    stub_google_auth(users(:me)) do
      post "/maps/#{maps(:public_one).id}/pin_properties",
           params: { name: 'Parking', multiple: true, position: 2 },
           headers: authorization
    end

    assert_response :success

    property = PinProperty.find(JSON.parse(@response.body)['id'])

    assert_equal 'Parking', property.name
    assert_predicate property, :multiple?
    assert_equal users(:me), property.current_revision.user
  end

  test 'a coauthor can define a property' do
    stub_google_auth(users(:me)) do
      post "/maps/#{maps(:private_following).id}/pin_properties",
           params: { name: 'Parking' },
           headers: authorization
    end

    assert_response :success
    assert_equal maps(:private_following).id, PinProperty.find(JSON.parse(@response.body)['id']).map_id
  end

  test 'create on a map the user cannot edit is not found' do
    stub_google_auth(users(:me)) do
      post "/maps/#{maps(:public_unfollowing).id}/pin_properties",
           params: { name: 'Parking' },
           headers: authorization
    end

    assert_response :not_found
  end

  test 'create without a name is unprocessable' do
    stub_google_auth(users(:me)) do
      post "/maps/#{maps(:public_one).id}/pin_properties", params: { name: '' }, headers: authorization
    end

    assert_response :unprocessable_content
  end

  test 'update renames a property through a new revision' do
    property = pin_properties(:payment)

    stub_google_auth(users(:me)) do
      patch "/maps/#{maps(:public_one).id}/pin_properties/#{property.id}",
            params: { name: 'Payment methods' },
            headers: authorization
    end

    assert_response :success
    assert_equal 'Payment methods', JSON.parse(@response.body)['name']
    assert_equal 2, property.revisions.count
  end

  test 'update does not change whether a property takes several options' do
    property = pin_properties(:genre)

    stub_google_auth(users(:me)) do
      patch "/maps/#{maps(:public_one).id}/pin_properties/#{property.id}",
            params: { multiple: true },
            headers: authorization
    end

    assert_response :success
    assert_not property.reload.multiple?
  end

  test 'update through another map is not found' do
    stub_google_auth(users(:me)) do
      patch "/maps/#{maps(:public_two).id}/pin_properties/#{pin_properties(:payment).id}",
            params: { name: 'Moved' },
            headers: authorization
    end

    assert_response :not_found
  end

  test 'destroy records the removal as a revision' do
    property = pin_properties(:payment)

    stub_google_auth(users(:me)) do
      delete "/maps/#{maps(:public_one).id}/pin_properties/#{property.id}", headers: authorization
    end

    assert_response :success
    assert_predicate property.reload, :deleted?
  end

  test 'destroy on a map the user cannot edit is not found' do
    property = PinProperty.record!(user: users(:you), map: maps(:public_unfollowing), name: 'Parking')

    stub_google_auth(users(:me)) do
      delete "/maps/#{maps(:public_unfollowing).id}/pin_properties/#{property.id}", headers: authorization
    end

    assert_response :not_found
    assert_predicate property.reload, :published?
  end

  private

  def authorization
    { 'Authorization': 'Bearer dummytoken' }
  end
end
