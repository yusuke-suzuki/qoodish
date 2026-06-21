require 'test_helper'

class CoauthorshipInvitationTest < ActiveSupport::TestCase
  test 'accept creates a coauthorship and marks the invitation accepted' do
    invitation = coauthorship_invitations(:pending_you_to_me)

    assert_difference 'Coauthorship.count', 1 do
      invitation.accept!
    end

    assert invitation.accepted?
    assert Coauthorship.exists?(map: invitation.map, user: invitation.invitee)
  end

  test 'decline marks the invitation declined without creating a coauthorship' do
    invitation = coauthorship_invitations(:pending_you_to_me)

    assert_no_difference 'Coauthorship.count' do
      invitation.decline!
    end

    assert invitation.declined?
  end

  test 'duplicate pending invitation is invalid' do
    existing = coauthorship_invitations(:pending_you_to_me)
    duplicate = CoauthorshipInvitation.new(
      map: existing.map,
      inviter: existing.inviter,
      invitee: existing.invitee
    )

    assert_not duplicate.valid?
  end

  test 'author cannot be invited as a coauthor' do
    map = maps(:public_one)
    invitation = CoauthorshipInvitation.new(map: map, inviter: users(:you), invitee: map.user)

    assert_not invitation.valid?
  end

  test 'accept succeeds even if the invitee is already a coauthor' do
    invitation = coauthorship_invitations(:pending_you_to_me)
    Coauthorship.create!(map: invitation.map, user: invitation.invitee)

    assert_nothing_raised { invitation.accept! }
    assert invitation.reload.accepted?
  end

  test 'decline succeeds even if the invitee is already a coauthor' do
    invitation = coauthorship_invitations(:pending_you_to_me)
    Coauthorship.create!(map: invitation.map, user: invitation.invitee)

    assert_nothing_raised { invitation.decline! }
    assert invitation.reload.declined?
  end

  test 'existing coauthor cannot be invited again' do
    map = maps(:private_following) # author: you, coauthor: me (me_on_private_following)
    invitation = CoauthorshipInvitation.new(map: map, inviter: map.user, invitee: users(:me))

    assert_not invitation.valid?
  end

  test 'creating an invitation notifies the invitee' do
    map = maps(:public_one)

    assert_difference 'Notification.count', 1 do
      CoauthorshipInvitation.create!(map: map, inviter: map.user, invitee: users(:you))
    end

    notification = Notification.last
    assert_equal 'coauthor_invited', notification.key
    assert_equal users(:you), notification.recipient
  end
end
