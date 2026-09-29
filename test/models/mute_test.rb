require 'test_helper'

class MuteTest < ActiveSupport::TestCase
  test 'a user can mute another user' do
    mute = Mute.new(muter: users(:me), muted: users(:you))

    assert mute.valid?
  end

  test 'a user cannot mute themselves' do
    mute = Mute.new(muter: users(:me), muted: users(:me))

    assert_not mute.valid?
    assert mute.errors.of_kind?(:muted_id, :other_than)
  end

  test 'a user cannot mute an account they are already muting' do
    Mute.create!(muter: users(:me), muted: users(:you))
    duplicate = Mute.new(muter: users(:me), muted: users(:you))

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:muted_id, :taken)
  end

  test 'muting again after a lift records a new mute and keeps the old one' do
    first = Mute.create!(muter: users(:me), muted: users(:you))
    Unmute.create!(mute: first)

    second = Mute.create!(muter: users(:me), muted: users(:you))

    assert_equal [first, second], users(:me).mutes.order(:id).to_a
    assert_equal [second], users(:me).active_mutes.to_a
  end

  test 'muting is one-directional' do
    Mute.create!(muter: users(:me), muted: users(:you))

    assert_equal [users(:you)], users(:me).muted_users.to_a
    assert_empty users(:you).muted_users
  end

  test 'a recorded mute cannot be changed or deleted' do
    mute = Mute.create!(muter: users(:me), muted: users(:you))

    assert_raises(ActiveRecord::ReadOnlyRecord) { mute.update!(created_at: 1.day.ago) }
    assert_raises(ActiveRecord::ReadOnlyRecord) { mute.destroy! }
  end

  test 'deleting either account removes its mutes and their lifts' do
    mute = Mute.create!(muter: users(:me), muted: users(:you))
    Unmute.create!(mute: mute)

    stub_identity_platform { users(:you).destroy! }

    assert_not Mute.exists?(mute.id)
    assert_not Unmute.exists?(mute_id: mute.id)
  end

  test 'every error message is worded in each locale' do
    I18n.available_locales.combination(2).each do |one, other|
      assert_equal error_message_keys(:mute, one), error_message_keys(:mute, other),
                   "#{one} and #{other} word different Mute errors"
    end
  end
end
