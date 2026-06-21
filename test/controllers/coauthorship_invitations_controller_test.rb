require 'test_helper'

class CoauthorshipInvitationsControllerTest < ActionDispatch::IntegrationTest
  test 'index returns pending invitations received by the current user' do
    stub_google_auth(users(:me)) do
      get '/coauthorship_invitations', headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success

    res = JSON.parse(@response.body)

    assert(res.any? { |invitation| invitation['id'] == coauthorship_invitations(:pending_you_to_me).id })
  end

  test 'accept creates a coauthorship for the invitee' do
    invitation = coauthorship_invitations(:pending_you_to_me)

    stub_google_auth(users(:me)) do
      post "/coauthorship_invitations/#{invitation.id}/accept",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert Coauthorship.exists?(map: invitation.map, user: users(:me))
    assert invitation.reload.accepted?
  end

  test 'decline marks the invitation declined' do
    invitation = coauthorship_invitations(:pending_you_to_me)

    stub_google_auth(users(:me)) do
      post "/coauthorship_invitations/#{invitation.id}/decline",
           headers: { 'Authorization': 'Bearer dummytoken' }
    end

    assert_response :success
    assert invitation.reload.declined?
  end
end
