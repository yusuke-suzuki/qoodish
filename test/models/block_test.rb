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

  test 'every error message is worded in each locale' do
    I18n.available_locales.combination(2).each do |one, other|
      assert_equal error_message_keys(:block, one), error_message_keys(:block, other),
                   "#{one} and #{other} word different Block errors"
    end
  end
end
