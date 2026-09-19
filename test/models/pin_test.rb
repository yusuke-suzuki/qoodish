require 'test_helper'

class PinTest < ActiveSupport::TestCase
  test 'image_variants returns the first image variants hash' do
    pin = pins(:public_one)
    expected = pin.images.first.variants

    assert_equal expected, pin.image_variants
  end

  test 'image_variants returns nil when the pin has no images' do
    pin = pins(:public_two)
    assert_empty pin.images

    assert_nil pin.image_variants
  end

  test 'publish! records the first revision and points the pin at it' do
    pin = publish(name: 'Cafe Bonjour')

    assert_equal 1, pin.revisions.count
    assert_equal pin.revisions.last, pin.current_revision
    assert_predicate pin, :published?
  end

  test 'name and comment drop carriage returns on assignment' do
    pin = publish(name: "Cafe\r\nBonjour", comment: "Nice\r\nplace")

    assert_equal "Cafe\nBonjour", pin.reload.name
    assert_equal "Nice\nplace", pin.comment
  end

  test 'revise! appends a revision and leaves the previous one untouched' do
    pin = pins(:public_one)
    previous = pin.current_revision

    pin.revise!(user: users(:me), name: 'renamed')

    assert_equal 'renamed', pin.reload.name
    assert_equal 2, pin.revisions.count
    assert_not_equal previous, pin.current_revision
    assert_equal 'This is a name', previous.reload.name
  end

  test 'revise! keeps the images of the previous revision when none are given' do
    pin = pins(:public_one)
    image_ids = pin.images.ids

    pin.revise!(user: users(:me), name: 'renamed')

    assert_equal image_ids, pin.reload.images.ids
  end

  test 'revise! leaves the images of the previous revision in place' do
    pin = pins(:public_one)
    previous = pin.current_revision

    pin.revise!(user: users(:me), image_ids: [])

    assert_empty pin.reload.images
    assert_equal 2, previous.images.count
  end

  test 'a revision cannot be rewritten' do
    revision = pins(:public_one).current_revision

    assert_raises(ActiveRecord::ReadonlyAttributeError) { revision.update!(name: 'rewritten') }
  end

  test 'delete! records the removal as a revision instead of dropping the row' do
    pin = pins(:public_one)

    assert_difference -> { pin.revisions.count }, 1 do
      pin.delete!(user: users(:me))
    end

    assert_predicate pin.reload, :deleted?
    assert_predicate pin.current_revision, :deleted?
    assert_not_includes Pin.published, pin
  end

  test 'delete! keeps the images the revisions reference' do
    pin = pins(:public_one)

    pin.delete!(user: users(:me))

    assert_equal 2, Image.where(id: [images(:one).id, images(:two).id]).count
  end

  private

  def publish(**content)
    Pin.publish!(
      user: users(:me),
      map_id: maps(:public_one).id,
      **{
        name: 'This is a name',
        comment: 'This is a comment',
        latitude: 35.681382,
        longitude: 139.766084
      }.merge(content)
    )
  end
end
