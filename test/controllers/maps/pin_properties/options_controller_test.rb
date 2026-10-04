require 'test_helper'

class Maps::PinProperties::OptionsControllerTest < ActionDispatch::IntegrationTest
  test 'create offers an option on a property of a map the user owns' do
    stub_google_auth(users(:me)) do
      post options_path(pin_properties(:payment)), params: { name: 'Card', position: 2 }, headers: authorization
    end

    assert_response :success

    option = PinPropertyOption.find(JSON.parse(@response.body)['id'])

    assert_equal 'Card', option.name
    assert_equal pin_properties(:payment), option.pin_property
  end

  test 'create on a discarded property is not found' do
    property = pin_properties(:payment)
    property.discard!(user: users(:me))

    stub_google_auth(users(:me)) do
      post options_path(property), params: { name: 'Card' }, headers: authorization
    end

    assert_response :not_found
  end

  test 'create on a map the user cannot edit is not found' do
    property = PinProperty.record!(user: users(:you), map: maps(:public_unfollowing), name: 'Parking')

    stub_google_auth(users(:me)) do
      post options_path(property), params: { name: 'Free' }, headers: authorization
    end

    assert_response :not_found
  end

  test 'create without a name is unprocessable' do
    stub_google_auth(users(:me)) do
      post options_path(pin_properties(:payment)), params: { name: '' }, headers: authorization
    end

    assert_response :unprocessable_content
  end

  test 'update renames an option through a new revision' do
    option = pin_property_options(:paypay)

    stub_google_auth(users(:me)) do
      patch "#{options_path(option.pin_property)}/#{option.id}",
            params: { name: 'PayPay accepted' },
            headers: authorization
    end

    assert_response :success
    assert_equal 'PayPay accepted', JSON.parse(@response.body)['name']
    assert_equal 2, option.revisions.count
  end

  test 'update through another property is not found' do
    option = pin_property_options(:paypay)

    stub_google_auth(users(:me)) do
      patch "#{options_path(pin_properties(:genre))}/#{option.id}", params: { name: 'Moved' }, headers: authorization
    end

    assert_response :not_found
  end

  test 'destroy records the removal as a revision' do
    option = pin_property_options(:paypay)

    stub_google_auth(users(:me)) do
      delete "#{options_path(option.pin_property)}/#{option.id}", headers: authorization
    end

    assert_response :success
    assert_predicate option.reload, :deleted?
  end

  private

  def options_path(property)
    "/maps/#{property.map_id}/pin_properties/#{property.id}/options"
  end

  def authorization
    { 'Authorization': 'Bearer dummytoken' }
  end
end
