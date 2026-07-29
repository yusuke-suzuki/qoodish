require 'test_helper'

class Me::MapsControllerTest < ActionDispatch::IntegrationTest
  test 'index should return own maps including private ones' do
    stub_google_auth(users(:me)) do
      get '/me/maps', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert_equal users(:me).maps.pluck(:id).sort,
                 res.map { |map| map['id'] }.sort
  end

  test 'index without a token should be unauthorized' do
    get '/me/maps'

    assert_response :unauthorized
  end
end
