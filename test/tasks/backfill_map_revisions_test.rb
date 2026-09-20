require 'test_helper'

class BackfillMapRevisionsTest < ActiveSupport::TestCase
  TASK = Rails.root.join('lib/tasks/backfill_map_revisions.rb').to_s

  test 'gives a map without a revision its first one' do
    map = detach_revision(maps(:public_one))

    run_task

    revision = map.reload.current_revision

    assert_equal map.revisions.last, revision
    assert_equal map.name, revision.name
    assert_equal map.description, revision.description
    assert_equal map.private, revision.private
    assert_predicate revision, :published?
  end

  test 'records the images the legacy imageable column holds' do
    map = detach_revision(maps(:public_two))
    image = users(:me).owned_images.create!(
      imageable: map,
      url: 'https://imagedelivery.net/mockhash/map-backfill/public'
    )

    run_task

    assert_equal [image.id], map.reload.images.ids
  end

  test 'records more images than a caller may submit' do
    map = detach_revision(maps(:public_two))
    2.times do |index|
      users(:me).owned_images.create!(
        imageable: map,
        url: "https://imagedelivery.net/mockhash/map-backfill-#{index}/public"
      )
    end

    run_task

    assert_equal 2, map.reload.images.count
  end

  test 'leaves the map last updated when it was' do
    map = detach_revision(maps(:public_one))
    updated_at = map.updated_at

    run_task

    assert_equal updated_at, map.reload.updated_at
    assert_equal updated_at, map.current_revision.created_at
  end

  test 'a second run appends nothing' do
    detach_revision(maps(:public_one))

    run_task

    assert_no_difference 'MapRevision.count' do
      run_task
    end
  end

  private

  def run_task
    capture_io { load TASK }
  end

  # The fixtures already carry a revision, so the state the backfill exists for
  # has to be restored first.
  def detach_revision(map)
    map.update_column(:current_revision_id, nil)
    map.revisions.destroy_all
    map
  end
end
