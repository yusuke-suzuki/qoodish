require 'test_helper'

class UnmuteTest < ActiveSupport::TestCase
  test 'lifting a mute ends it without erasing it' do
    mute = Mute.create!(muter: users(:me), muted: users(:you))

    Unmute.create!(mute: mute)

    assert Mute.exists?(mute.id)
    assert_empty Mute.active.where(id: mute.id)
    assert_empty users(:me).muted_users
  end

  test 'a mute cannot be lifted twice' do
    mute = Mute.create!(muter: users(:me), muted: users(:you))
    Unmute.create!(mute: mute)

    duplicate = Unmute.new(mute: mute)

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:mute_id, :taken)
  end

  test 'the database refuses a second lift that slips past validation' do
    mute = Mute.create!(muter: users(:me), muted: users(:you))
    Unmute.create!(mute: mute)

    assert_raises(ActiveRecord::RecordNotUnique) { Unmute.new(mute: mute).save!(validate: false) }
  end

  test 'a recorded lift cannot be deleted' do
    unmute = Unmute.create!(mute: Mute.create!(muter: users(:me), muted: users(:you)))

    assert_raises(ActiveRecord::ReadOnlyRecord) { unmute.destroy! }
  end

  test 'every error message is worded in each locale' do
    I18n.available_locales.combination(2).each do |one, other|
      assert_equal error_message_keys(:unmute, one), error_message_keys(:unmute, other),
                   "#{one} and #{other} word different Unmute errors"
    end
  end
end
