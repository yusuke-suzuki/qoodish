require 'test_helper'

class PinPropertyTest < ActiveSupport::TestCase
  test 'record! writes the first revision and points the property at it' do
    property = define(name: 'Parking')

    assert_equal 1, property.revisions.count
    assert_equal property.revisions.last, property.current_revision
    assert_equal users(:me), property.current_revision.user
  end

  test 'revise! appends a revision and leaves the previous one untouched' do
    property = pin_properties(:payment)
    previous = property.current_revision

    property.revise!(user: users(:you), name: 'Payment methods')

    assert_equal 'Payment methods', property.reload.name
    assert_equal 2, property.revisions.count
    assert_equal 'Payment', previous.reload.name
    assert_equal users(:you), property.current_revision.user
  end

  test 'discard! records the removal as a revision instead of dropping the row' do
    property = pin_properties(:payment)

    assert_difference -> { property.revisions.count }, 1 do
      property.discard!(user: users(:me))
    end

    assert_predicate property.reload, :deleted?
    assert_predicate property.current_revision, :deleted?
  end

  test 'whether a property takes several options is fixed at creation' do
    assert_raises(ActiveRecord::ReadonlyAttributeError) do
      pin_properties(:genre).revise!(user: users(:me), multiple: true)
    end
  end

  test 'name drops surrounding whitespace' do
    assert_equal 'Parking', define(name: "  Parking\n").name
  end

  test 'name is required' do
    assert_raises(ActiveRecord::RecordInvalid) { define(name: ' ') }
  end

  test 'name longer than 30 characters is rejected' do
    assert_raises(ActiveRecord::RecordInvalid) { define(name: 'a' * 31) }
  end

  test 'erasing a coauthor leaves the revisions they wrote standing' do
    property = PinProperty.record!(user: users(:me), map: maps(:private_following), name: 'Parking')
    revision = property.current_revision

    stub_identity_platform { stub_cloudflare_images { users(:me).destroy! } }

    assert_nil revision.reload.user_id
    assert_equal 'Parking', revision.name
  end

  test 'destroying a map takes its properties and the options pins chose with it' do
    map = maps(:public_one)
    chosen_option_id = pin_property_options(:paypay).id

    stub_cloudflare_images { map.destroy! }

    assert_not PinProperty.exists?(map_id: map.id)
    assert_not PinRevisionPropertyOption.exists?(pin_property_option_id: chosen_option_id)
  end

  private

  def define(**content)
    PinProperty.record!(user: users(:me), map: maps(:public_one), **content)
  end
end
