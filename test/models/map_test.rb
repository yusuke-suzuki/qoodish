require 'test_helper'

class MapTest < ActiveSupport::TestCase
  test 'referenceable_by includes public maps, own maps and coauthored maps' do
    ids = Map.referenceable_by(users(:me)).pluck(:id)

    assert_includes ids, maps(:public_one).id              # own
    assert_includes ids, maps(:public_unfollowing).id      # public, someone else's
    assert_includes ids, maps(:private_following).id       # coauthored (me_on_private_following)
    assert_not_includes ids, maps(:private_unfollowing).id # someone else's private, not coauthor
  end

  test 'editable_by includes own and coauthored maps only' do
    ids = Map.editable_by(users(:me)).pluck(:id)

    assert_includes ids, maps(:public_one).id
    assert_includes ids, maps(:private_following).id
    assert_not_includes ids, maps(:public_unfollowing).id # public but not author/coauthor
  end

  test 'bookmarked_by returns only bookmarked maps' do
    ids = Map.bookmarked_by(users(:you)).pluck(:id)

    assert_includes ids, maps(:public_one).id # you_on_public_one
    assert_not_includes ids, maps(:public_two).id
  end

  test 'related_to combines authored, coauthored and bookmarked maps' do
    ids = Map.related_to(users(:me)).pluck(:id)

    assert_includes ids, maps(:public_one).id             # authored
    assert_includes ids, maps(:private_following).id      # coauthored
    assert_not_includes ids, maps(:public_unfollowing).id # not related
  end

  test 'related_to excludes a bookmarked map that is private' do
    map = maps(:public_one) # bookmarked by you (you_on_public_one)
    map.update_column(:private, true) # simulate a stale bookmark, bypassing the callback

    assert_not_includes Map.related_to(users(:you)).pluck(:id), map.id
  end

  test 'name and description drop carriage returns on assignment' do
    map = users(:me).maps.record!(
      user: users(:me),
      name: "Kyoto\r\ntrip",
      description: "First\r\nvisit"
    )

    assert_equal "Kyoto\ntrip", map.reload.name
    assert_equal "First\nvisit", map.description
  end

  test 'making a map private destroys its bookmarks' do
    map = maps(:public_one) # bookmarked by you (you_on_public_one)

    assert map.bookmarks.exists?

    map.revise!(user: users(:me), private: true)

    assert_not map.bookmarks.exists?
  end

  test 'erasing a coauthor leaves the revisions they wrote standing' do
    map = maps(:private_following) # author: you, coauthor: me
    map.revise!(user: users(:me), name: 'Renamed by the coauthor')
    revision = map.current_revision

    stub_identity_platform { stub_cloudflare_images { users(:me).destroy! } }

    assert_nil revision.reload.user_id
    assert_equal 'Renamed by the coauthor', revision.name
  end

  test 'revising before the backfill keeps the images the legacy column holds' do
    map = maps(:public_two)
    map.update_column(:current_revision_id, nil)
    map.revisions.destroy_all
    image = attach_legacy_image(map, 'map-pre-backfill')

    map.reload.revise!(user: users(:me), name: 'Renamed')

    assert_equal [image.id], map.reload.images.ids
  end

  test 'clearing the images before the backfill is recorded' do
    map = maps(:public_two)
    map.update_column(:current_revision_id, nil)
    map.revisions.destroy_all
    attach_legacy_image(map, 'map-pre-backfill-cleared')

    map.reload.revise!(user: users(:me), image_ids: [])

    assert_equal 1, map.reload.revisions.count
    assert_empty map.images.ids
  end

  test 'a revision carries the images the one before it held' do
    map = maps(:public_two)
    image = users(:me).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/map-carried/public'
    )
    map.revise!(user: users(:me), image_ids: [image.id])

    map.revise!(user: users(:me), name: 'Renamed')

    assert_equal [image.id], map.reload.images.ids
  end

  test 'clearing the images is recorded' do
    map = maps(:public_two)
    image = users(:me).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/map-cleared/public'
    )
    map.revise!(user: users(:me), image_ids: [image.id])

    assert_difference -> { map.revisions.count }, 1 do
      map.revise!(user: users(:me), image_ids: [])
    end

    assert_empty map.reload.images.ids
    assert_equal [image.id], map.revisions.order(:id).last(2).first.image_ids
  end

  test 'content cannot be changed outside a revision' do
    map = maps(:public_one)

    assert_raises(ActiveRecord::ReadOnlyRecord) { map.update!(name: 'Renamed') }
    assert_equal 'Public map', map.reload.name
  end

  test 'record! writes the first revision and points the map at it' do
    map = publish(name: 'Kyoto trip')

    assert_equal 1, map.revisions.count
    assert_equal map.revisions.last, map.current_revision
    assert_predicate map, :published?
  end

  test 'revise! appends a revision and leaves the previous one untouched' do
    map = maps(:public_one)
    previous = map.current_revision

    map.revise!(user: users(:me), name: 'Renamed')

    assert_equal 'Renamed', map.reload.name
    assert_equal 2, map.revisions.count
    assert_not_equal previous, map.current_revision
    assert_equal 'Public map', previous.reload.name
  end

  test 'revise! records the visibility it was given' do
    map = maps(:public_one)

    map.revise!(user: users(:me), private: true)

    assert_predicate map.current_revision, :private
  end

  test 'a revision cannot be rewritten' do
    revision = maps(:public_one).current_revision

    assert_raises(ActiveRecord::ReadonlyAttributeError) { revision.update!(name: 'rewritten') }
  end

  test 'revising with what the map already says appends nothing' do
    map = maps(:public_one)

    assert_no_difference -> { map.revisions.count } do
      map.revise!(user: users(:me), name: map.name, description: map.description)
      map.revise!(user: users(:me), image_ids: map.images.ids)
    end
  end

  test 'a revision keeps the images it was written with' do
    revision = record_revision(maps(:public_two), [images(:one)])

    assert_raises(ActiveRecord::ReadOnlyRecord) { revision.images = [] }
    assert_raises(ActiveRecord::ReadOnlyRecord) { revision.image_ids = [] }
    assert_equal 1, revision.reload.images.count
  end

  test 'a revision refuses every way of mutating the collection it was written with' do
    revision = record_revision(maps(:public_two), [images(:one)])

    assert_raises(ActiveRecord::ReadOnlyRecord) { revision.images << images(:two) }
    assert_raises(ActiveRecord::ReadOnlyRecord) { revision.images.delete(images(:one)) }
    assert_raises(ActiveRecord::ReadOnlyRecord) { revision.images.destroy(images(:one)) }
    assert_raises(ActiveRecord::ReadOnlyRecord) { revision.images.clear }
    assert_raises(ActiveRecord::ReadOnlyRecord) { revision.images.create!(user: users(:me), url: 'https://example.com/x') }

    assert_equal [images(:one).id], revision.reload.image_ids
  end

  test 'a revision still takes the images it is written with' do
    revision = record_revision(maps(:public_two), [images(:one)])

    assert_equal [images(:one).id], revision.image_ids
  end

  test 'discard! records the removal as a revision instead of dropping the row' do
    map = maps(:public_one)

    assert_difference -> { map.revisions.count }, 1 do
      map.discard!(user: users(:me))
    end

    assert_predicate map.reload, :deleted?
    assert_predicate map.current_revision, :deleted?
    assert_not_includes Map.public_open, map
    assert_not_includes Map.referenceable_by(users(:me)), map
    assert_not_includes Map.editable_by(users(:me)), map
  end

  test 'deleting a map hides its pins' do
    map = maps(:public_one)
    pin = pins(:public_one)

    assert_includes Pin.public_open, pin

    map.discard!(user: users(:me))

    assert_not_includes Pin.public_open, pin
    assert_predicate pin.reload, :published?
  end

  test 'a written revision becomes the current one' do
    map = maps(:public_two)

    revision = record_revision(map, [])

    assert_equal revision, map.reload.current_revision
  end

  test 'a backfilled revision leaves the map last updated when it was' do
    map = maps(:public_two)
    updated_at = map.updated_at

    record_revision(map, [])

    assert_equal updated_at, map.reload.updated_at
  end

  test 'a map holding more images than the limit can still be revised' do
    map = maps(:public_two)
    record_revision(map, legacy_images(2))

    map.reload.revise!(user: users(:me), name: 'Renamed')

    assert_equal 'Renamed', map.reload.name
    assert_equal 2, map.images.count
  end

  test 'submitting an image another user uploaded is rejected' do
    foreign_image = users(:you).owned_images.create!(
      url: 'https://imagedelivery.net/mockhash/map-foreign/public'
    )

    assert_raises(ActiveRecord::RecordInvalid) do
      maps(:public_two).revise!(user: users(:me), image_ids: [foreign_image.id])
    end
  end

  test 'submitting more images than the limit is rejected' do
    map = maps(:public_two)

    assert_raises(ActiveRecord::RecordInvalid) do
      map.revise!(user: users(:me), image_ids: legacy_images(2).map(&:id))
    end
  end

  private

  # Image ignores the legacy columns, so the state the fallback exists for can
  # only be written past it.
  def attach_legacy_image(map, slug)
    image = users(:me).owned_images.create!(
      url: "https://imagedelivery.net/mockhash/#{slug}/public"
    )
    Image.connection.execute(
      "UPDATE images SET imageable_type = 'Map', imageable_id = #{map.id} WHERE id = #{image.id}"
    )
    image
  end

  def legacy_images(count)
    Array.new(count) do |index|
      users(:me).owned_images.create!(
        url: "https://imagedelivery.net/mockhash/map-legacy-#{index}/public"
      )
    end
  end

  # Records a revision the way the backfill does, without a caller submitting
  # the images.
  def record_revision(map, images)
    map.revisions.create!(
      user_id: map.user_id,
      status: map.status,
      name: map.name,
      description: map.description,
      latitude: map.latitude,
      longitude: map.longitude,
      private: map.private,
      image_ids: images.map(&:id)
    )
  end

  def publish(**content)
    Map.record!(
      user: users(:me),
      **{
        name: 'This is a name',
        description: 'This is a description',
        latitude: 35.681382,
        longitude: 139.766084
      }.merge(content)
    )
  end
end
