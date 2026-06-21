require 'test_helper'

class Maps::CoauthorshipInvitationsControllerTest < ActionDispatch::IntegrationTest
  test 'author can invite a coauthor' do
    assert_difference 'CoauthorshipInvitation.count', 1 do
      stub_google_auth(users(:me)) do
        post "/maps/#{maps(:public_two).id}/coauthorship_invitations",
             params: { user_id: users(:you).id },
             headers: { 'Authorization': 'Bearer dummytoken' }
      end
    end

    assert_response :success
  end

  test 'inviting on a non-editable map raises not found error' do
    stub_google_auth(users(:me)) do
      post "/maps/#{maps(:private_unfollowing).id}/coauthorship_invitations",
           params: { user_id: users(:you).id },
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :not_found
  end
end
