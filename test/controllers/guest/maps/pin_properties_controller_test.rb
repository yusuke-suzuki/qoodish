require 'test_helper'

class Guest::Maps::PinPropertiesControllerTest < ActionDispatch::IntegrationTest
  test 'index lists the properties of a public map' do
    get "/guest/maps/#{maps(:public_one).id}/pin_properties"

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal [pin_properties(:payment).id, pin_properties(:genre).id], res.pluck('id')
  end

  test 'index on a private map is not found' do
    get "/guest/maps/#{maps(:private).id}/pin_properties"

    assert_response :not_found
  end
end
