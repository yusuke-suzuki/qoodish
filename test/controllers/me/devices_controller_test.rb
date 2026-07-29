require 'test_helper'

class Me::DevicesControllerTest < ActionDispatch::IntegrationTest
  test 'update registers a new device' do
    assert_difference 'users(:me).devices.count', 1 do
      stub_google_auth(users(:me)) do
        put '/me/devices/newregistrationtoken',
            headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
    assert users(:me).devices.exists?(registration_token: 'newregistrationtoken')
  end

  test 'update with an existing token does not duplicate the device' do
    assert_no_difference 'users(:me).devices.count' do
      stub_google_auth(users(:me)) do
        put "/me/devices/#{device(:notifier).registration_token}",
            headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
  end

  test 'destroy removes the device' do
    assert_difference 'users(:me).devices.count', -1 do
      stub_google_auth(users(:me)) do
        delete "/me/devices/#{device(:notifier).registration_token}",
               headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
  end

  test 'destroy with an unknown token should be success' do
    assert_no_difference 'Device.count' do
      stub_google_auth(users(:me)) do
        delete '/me/devices/unknowntoken',
               headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
  end
end
