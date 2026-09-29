require 'test_helper'

class UnblockTest < ActiveSupport::TestCase
  test 'lifting a block ends it without erasing it' do
    block = Block.create!(blocker: users(:me), blocked: users(:you))

    Unblock.create!(block: block)

    assert Block.exists?(block.id)
    assert_empty Block.active.where(id: block.id)
    assert_empty users(:me).blocked_users
  end

  test 'a block cannot be lifted twice' do
    block = Block.create!(blocker: users(:me), blocked: users(:you))
    Unblock.create!(block: block)

    duplicate = Unblock.new(block: block)

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:block_id, :taken)
  end

  test 'the database refuses a second lift that slips past validation' do
    block = Block.create!(blocker: users(:me), blocked: users(:you))
    Unblock.create!(block: block)

    assert_raises(ActiveRecord::RecordNotUnique) { Unblock.new(block: block).save!(validate: false) }
  end

  test 'a recorded lift cannot be deleted' do
    unblock = Unblock.create!(block: Block.create!(blocker: users(:me), blocked: users(:you)))

    assert_raises(ActiveRecord::ReadOnlyRecord) { unblock.destroy! }
  end

  test 'every error message is worded in each locale' do
    I18n.available_locales.combination(2).each do |one, other|
      assert_equal error_message_keys(:unblock, one), error_message_keys(:unblock, other),
                   "#{one} and #{other} word different Unblock errors"
    end
  end
end
