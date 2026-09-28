require 'test_helper'

class BlockTest < ActiveSupport::TestCase
  test 'a user can block another user' do
    block = Block.new(blocker: users(:me), blocked: users(:you))

    assert block.valid?
  end

  test 'a user cannot block themselves' do
    block = Block.new(blocker: users(:me), blocked: users(:me))

    assert_not block.valid?
    assert block.errors.of_kind?(:blocked_id, :other_than)
  end

  test 'a user cannot block an account they are already blocking' do
    Block.create!(blocker: users(:me), blocked: users(:you))
    duplicate = Block.new(blocker: users(:me), blocked: users(:you))

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:blocked_id, :taken)
  end

  test 'blocking again after a lift records a new block and keeps the old one' do
    first = Block.create!(blocker: users(:me), blocked: users(:you))
    Unblock.create!(block: first)

    second = Block.create!(blocker: users(:me), blocked: users(:you))

    assert_equal [first, second], users(:me).blocks.order(:id).to_a
    assert_equal [second], users(:me).active_blocks.to_a
  end

  test 'blocking is one-directional' do
    Block.create!(blocker: users(:me), blocked: users(:you))

    assert Block.new(blocker: users(:you), blocked: users(:me)).valid?
    assert_equal [users(:you)], users(:me).blocked_users.to_a
    assert_empty users(:you).blocked_users
  end

  test 'a recorded block cannot be changed or deleted' do
    block = Block.create!(blocker: users(:me), blocked: users(:you))

    assert_raises(ActiveRecord::ReadOnlyRecord) { block.update!(created_at: 1.day.ago) }
    assert_raises(ActiveRecord::ReadOnlyRecord) { block.destroy! }
  end

  test 'deleting either account removes its blocks and their lifts' do
    block = Block.create!(blocker: users(:me), blocked: users(:you))
    Unblock.create!(block: block)

    stub_identity_platform { users(:you).destroy! }

    assert_not Block.exists?(block.id)
    assert_not Unblock.exists?(block_id: block.id)
  end

  test 'blocking removes the bookmarks each side holds on the other' do
    Bookmark.create!(map: maps(:public_unfollowing), user: users(:me))
    JournalBookmark.create!(journal: journals(:my_journal), user: users(:you))

    users(:me).block!(users(:you))

    assert_not Bookmark.exists?(map: maps(:public_one), user: users(:you))
    assert_not Bookmark.exists?(map: maps(:public_unfollowing), user: users(:me))
    assert_not JournalBookmark.exists?(journal: journals(:my_journal), user: users(:you))
  end

  test 'blocking ends the coauthorships each side holds on the other' do
    users(:me).block!(users(:you))

    assert_not Coauthorship.exists?(map: maps(:private), user: users(:you))
    assert_not Coauthorship.exists?(map: maps(:private_following), user: users(:me))
  end

  test 'blocking declines pending invitations between the two' do
    invitation = CoauthorshipInvitation.create!(map: maps(:public_two), inviter: users(:me), invitee: users(:you))

    users(:you).block!(users(:me))

    assert_predicate invitation.reload, :declined?
  end

  test 'blocking declines pending invitations to either map from a third member' do
    third = record_user('third')
    Coauthorship.create!(map: maps(:public_two), user: third)
    Coauthorship.create!(map: maps(:private_unfollowing), user: third)
    to_blocked = CoauthorshipInvitation.create!(map: maps(:public_two), inviter: third, invitee: users(:you))
    to_blocker = CoauthorshipInvitation.create!(map: maps(:private_unfollowing), inviter: third, invitee: users(:me))

    users(:me).block!(users(:you))

    assert_predicate to_blocked.reload, :declined?
    assert_predicate to_blocker.reload, :declined?
  end

  test 'neither side can interact with the other while blocked' do
    users(:me).block!(users(:you))

    assert_raises(ActiveRecord::RecordInvalid) { users(:you).liked!(pins(:public_one)) }
    assert_raises(ActiveRecord::RecordInvalid) { users(:me).liked!(pins(:public_unfollowing_you)) }
    assert_raises(ActiveRecord::RecordInvalid) do
      Comment.record!(user: users(:me), commentable: pins(:public_unfollowing_you), body: 'hello')
    end
    assert_not Bookmark.new(map: maps(:public_unfollowing), user: users(:me)).valid?
    assert_not JournalBookmark.new(journal: journals(:you_journal), user: users(:me)).valid?
    assert_not CoauthorshipInvitation.new(map: maps(:public_two), inviter: users(:me), invitee: users(:you)).valid?
  end

  test 'a refusal across a block reads as one sentence in each locale' do
    users(:me).block!(users(:you))
    vote = Vote.new(votable: pins(:public_unfollowing_you), voter: users(:me))

    messages = %i[en ja].index_with do |locale|
      I18n.with_locale(locale) do
        vote.valid?
        vote.errors.full_messages
      end
    end

    assert_equal ['You cannot like a post by an account you have blocked or that has blocked you.'], messages[:en]
    assert_equal ['ブロックしている、またはブロックされているアカウントの投稿にはいいねできません。'], messages[:ja]
  end

  test 'unblocking lets the two interact again' do
    block = users(:me).block!(users(:you))
    Unblock.create!(block: block)

    assert users(:me).liked!(pins(:public_unfollowing_you))
    assert Bookmark.new(map: maps(:public_unfollowing), user: users(:me)).valid?
  end

  test 'each refusal across a block is worded for what it refuses in each locale' do
    keys = %w[vote.attributes.voter_id comment.attributes.user_id bookmark.attributes.user_id
              journal_bookmark.attributes.user_id coauthorship_invitation.attributes.invitee_id]

    I18n.available_locales.each do |locale|
      keys.each do |key|
        assert I18n.exists?("activerecord.errors.models.#{key}.blocked_interaction", locale),
               "#{locale} has no refusal for #{key}"
      end
    end
  end

  test 'every error message is worded in each locale' do
    I18n.available_locales.combination(2).each do |one, other|
      assert_equal error_message_keys(:block, one), error_message_keys(:block, other),
                   "#{one} and #{other} word different Block errors"
    end
  end
end
