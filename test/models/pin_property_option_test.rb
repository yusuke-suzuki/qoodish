require 'test_helper'

class PinPropertyOptionTest < ActiveSupport::TestCase
  test 'record! writes the first revision and points the option at it' do
    option = offer(name: 'Card')

    assert_equal 1, option.revisions.count
    assert_equal option.revisions.last, option.current_revision
  end

  test 'revise! appends a revision and leaves the previous one untouched' do
    option = pin_property_options(:paypay)
    previous = option.current_revision

    option.revise!(user: users(:me), name: 'PayPay accepted')

    assert_equal 'PayPay accepted', option.reload.name
    assert_equal 2, option.revisions.count
    assert_equal 'PayPay', previous.reload.name
  end

  test 'discard! records the removal as a revision instead of dropping the row' do
    option = pin_property_options(:paypay)

    assert_difference -> { option.revisions.count }, 1 do
      option.discard!(user: users(:me))
    end

    assert_predicate option.reload, :deleted?
  end

  test 'name is required' do
    assert_raises(ActiveRecord::RecordInvalid) { offer(name: '') }
  end

  test 'name longer than 30 characters is rejected' do
    assert_raises(ActiveRecord::RecordInvalid) { offer(name: 'a' * 31) }
  end

  test 'an option is offered on the map of its property while both stand' do
    option = pin_property_options(:paypay)
    map_id = maps(:public_one).id

    assert option.offered_on?(map_id)
    assert_not option.offered_on?(maps(:public_two).id)

    option.pin_property.discard!(user: users(:me))

    assert_not option.reload.offered_on?(map_id)
  end

  test 'an option a pin revision chose cannot be destroyed' do
    assert_raises(ActiveRecord::InvalidForeignKey) { pin_property_options(:paypay).destroy! }
    assert_equal 2, pin_revisions(:public_one).property_options.count
  end

  private

  def offer(**content)
    PinPropertyOption.record!(user: users(:me), pin_property: pin_properties(:payment), **content)
  end
end
