require 'test_helper'

class ChapterTest < ActiveSupport::TestCase
  LEXICAL_DOCUMENT = {
    'root' => {
      'type' => 'root',
      'version' => 1,
      'children' => []
    }
  }.freeze

  test 'valid chapter without a journey' do
    chapter = Chapter.new(
      user: users(:you),
      map: maps(:public_unfollowing),
      title: 'A walk',
      content: LEXICAL_DOCUMENT
    )

    assert chapter.valid?
  end

  test 'content must be a lexical document' do
    chapter = Chapter.new(
      user: users(:you),
      map: maps(:public_unfollowing),
      title: 'A walk',
      content: { 'foo' => 'bar' }
    )

    assert_not chapter.valid?
  end

  test 'map features default to an empty feature collection' do
    chapter = Chapter.new(
      user: users(:you),
      map: maps(:public_unfollowing),
      title: 'A walk',
      content: LEXICAL_DOCUMENT
    )

    assert chapter.valid?
    assert_equal Chapter::EMPTY_FEATURE_COLLECTION, chapter.map_features
  end

  test 'valid chapter with point map features' do
    chapter = Chapter.new(
      user: users(:you),
      map: maps(:public_unfollowing),
      title: 'A walk',
      content: LEXICAL_DOCUMENT,
      map_features: {
        'type' => 'FeatureCollection',
        'features' => [
          {
            'type' => 'Feature',
            'geometry' => { 'type' => 'Point', 'coordinates' => [138.86, 35.1] },
            'properties' => { 'title' => 'Numazu', 'description' => 'Tsukemen' }
          }
        ]
      }
    )

    assert chapter.valid?
  end

  test 'map features keep unknown properties' do
    chapter = Chapter.new(
      user: users(:you),
      map: maps(:public_unfollowing),
      title: 'A walk',
      content: LEXICAL_DOCUMENT,
      map_features: {
        'type' => 'FeatureCollection',
        'features' => [
          {
            'type' => 'Feature',
            'geometry' => { 'type' => 'Point', 'coordinates' => [138.86, 35.1] },
            'properties' => { 'marker-color' => '#ff0000' }
          }
        ]
      }
    )

    assert chapter.valid?
  end

  test 'map features title must be a string' do
    chapter = Chapter.new(
      user: users(:you),
      map: maps(:public_unfollowing),
      title: 'A walk',
      content: LEXICAL_DOCUMENT,
      map_features: {
        'type' => 'FeatureCollection',
        'features' => [
          {
            'type' => 'Feature',
            'geometry' => { 'type' => 'Point', 'coordinates' => [138.86, 35.1] },
            'properties' => { 'title' => 42 }
          }
        ]
      }
    )

    assert_not chapter.valid?
  end

  test 'map features cannot be null' do
    chapter = Chapter.new(
      user: users(:you),
      map: maps(:public_unfollowing),
      title: 'A walk',
      content: LEXICAL_DOCUMENT,
      map_features: nil
    )

    assert_not chapter.valid?
  end

  test 'map features must be a feature collection' do
    chapter = Chapter.new(
      user: users(:you),
      map: maps(:public_unfollowing),
      title: 'A walk',
      content: LEXICAL_DOCUMENT,
      map_features: { 'foo' => 'bar' }
    )

    assert_not chapter.valid?
  end

  test 'map features geometry must be a point' do
    chapter = Chapter.new(
      user: users(:you),
      map: maps(:public_unfollowing),
      title: 'A walk',
      content: LEXICAL_DOCUMENT,
      map_features: {
        'type' => 'FeatureCollection',
        'features' => [
          {
            'type' => 'Feature',
            'geometry' => {
              'type' => 'LineString',
              'coordinates' => [[138.86, 35.1], [138.87, 35.11]]
            },
            'properties' => {}
          }
        ]
      }
    )

    assert_not chapter.valid?
  end

  test 'map features coordinates must be in range' do
    chapter = Chapter.new(
      user: users(:you),
      map: maps(:public_unfollowing),
      title: 'A walk',
      content: LEXICAL_DOCUMENT,
      map_features: {
        'type' => 'FeatureCollection',
        'features' => [
          {
            'type' => 'Feature',
            'geometry' => { 'type' => 'Point', 'coordinates' => [35.1, 138.86] },
            'properties' => {}
          }
        ]
      }
    )

    assert_not chapter.valid?
  end

  test 'journey of another user cannot be recorded' do
    chapter = Chapter.new(
      user: users(:you),
      map: maps(:public_one),
      journey: journeys(:my_finished),
      title: 'A walk',
      content: LEXICAL_DOCUMENT
    )

    assert_not chapter.valid?
  end

  test 'journey on another map cannot be recorded' do
    chapter = Chapter.new(
      user: users(:me),
      map: maps(:public_one),
      journey: journeys(:my_in_progress),
      title: 'A walk',
      content: LEXICAL_DOCUMENT
    )

    assert_not chapter.valid?
  end

  test 'journey cannot be recorded in two chapters' do
    chapter = Chapter.new(
      user: users(:me),
      map: maps(:public_one),
      journey: chapters(:my_draft).journey,
      title: 'A walk',
      content: LEXICAL_DOCUMENT
    )

    assert_not chapter.valid?
  end

  test 'destroying the map keeps the chapter without a map' do
    chapter = chapters(:my_draft)

    chapter.map.destroy!

    assert_nil chapter.reload.map_id
  end

  test 'record! writes the first revision and points the chapter at it' do
    chapter = Chapter.record!(
      user: users(:me),
      map: maps(:public_one),
      title: 'A new chapter',
      content: LEXICAL_DOCUMENT
    )

    assert_equal 1, chapter.revisions.count
    assert_equal chapter.revisions.last, chapter.current_revision
    assert_predicate chapter, :draft?
    assert_predicate chapter.current_revision, :draft?
  end

  test 'revise! appends a revision and leaves the previous one untouched' do
    chapter = chapters(:my_draft)
    previous = chapter.current_revision

    chapter.revise!(user: users(:me), title: 'Renamed')

    assert_equal 'Renamed', chapter.reload.title
    assert_equal 2, chapter.revisions.count
    assert_equal 'My draft chapter', previous.reload.title
  end

  test 'publishing is recorded as a revision' do
    chapter = chapters(:my_draft)

    chapter.revise!(user: users(:me), status: 'published')

    assert_predicate chapter.reload, :published?
    assert_predicate chapter.current_revision, :published?
  end

  test 'a revision cannot be rewritten' do
    revision = chapters(:my_draft).current_revision

    assert_raises(ActiveRecord::ReadonlyAttributeError) { revision.update!(title: 'rewritten') }
  end

  test 'content cannot be changed outside a revision' do
    chapter = chapters(:my_draft)

    assert_raises(ActiveRecord::ReadOnlyRecord) { chapter.update!(title: 'Renamed') }
    assert_equal 'My draft chapter', chapter.reload.title
  end

  test 'discard! records the removal as a revision instead of dropping the row' do
    chapter = chapters(:my_published)

    assert_difference -> { chapter.revisions.count }, 1 do
      chapter.discard!(user: users(:me))
    end

    assert_predicate chapter.reload, :deleted?
    assert_predicate chapter.current_revision, :deleted?
    assert_not_includes Chapter.readable_by(users(:me)), chapter
    assert_not_includes Chapter.public_open, chapter
  end

  test 'discarding a chapter frees its journey to be written up again' do
    chapter = chapters(:my_draft)
    journey = chapter.journey

    chapter.discard!(user: users(:me))

    assert_nil chapter.reload.journey_id
    assert_nil journey.reload.chapter

    rewritten = Chapter.record!(
      user: users(:me),
      map: maps(:public_one),
      journey: journey,
      title: 'A second attempt',
      content: LEXICAL_DOCUMENT
    )

    assert_equal journey, rewritten.journey
  end

  test 'a deleted chapter is no longer notified about' do
    chapter = chapters(:you_published_on_my_map)
    notification = Notification.create!(
      notifiable: chapter,
      notifier: users(:you),
      recipient: users(:me),
      key: 'published'
    )

    assert_predicate notification, :renderable?

    chapter.discard!(user: users(:you))

    assert_not_predicate notification.reload, :renderable?
  end

  test 'readable_by includes published chapters on referenceable maps' do
    readable = Chapter.readable_by(users(:me))

    assert_includes readable, chapters(:my_published)
    assert_includes readable, chapters(:you_published)
    assert_includes readable, chapters(:you_private_published_following)
  end

  test 'readable_by excludes published chapters on unreferenceable private maps' do
    readable = Chapter.readable_by(users(:me))

    assert_not_includes readable, chapters(:you_private_published_unfollowing)
  end

  test 'readable_by includes own drafts' do
    readable = Chapter.readable_by(users(:me))

    assert_includes readable, chapters(:my_draft)
  end

  test 'readable_by excludes drafts of other users' do
    readable = Chapter.readable_by(users(:me))

    assert_not_includes readable, chapters(:you_draft)
  end

  test 'public_open includes only published chapters on public maps' do
    public_chapters = Chapter.public_open

    assert_includes public_chapters, chapters(:my_published)
    assert_includes public_chapters, chapters(:you_published)
    assert_not_includes public_chapters, chapters(:you_private_published_following)
    assert_not_includes public_chapters, chapters(:my_draft)
  end

  test 'destroying a chapter destroys its notifications' do
    chapter = chapters(:you_published_on_my_map)
    Notification.create!(
      notifiable: chapter,
      notifier: users(:me),
      recipient: chapter.user,
      key: 'liked'
    )

    assert_difference 'Notification.count', -1 do
      chapter.destroy!
    end
  end

  test 'publishing a chapter notifies the map author' do
    chapter = chapters(:you_draft_on_my_map)

    assert_difference 'Notification.count', 1 do
      chapter.revise!(user: users(:you), status: 'published')
    end

    notification = Notification.last

    assert_equal 'published', notification.key
    assert_equal chapter, notification.notifiable
    assert_equal users(:you), notification.notifier
    assert_equal users(:me), notification.recipient
    assert_equal "/chapters/#{chapter.id}", notification.click_action
  end

  test 'publishing a chapter on own map notifies nobody' do
    assert_no_difference 'Notification.count' do
      chapters(:my_draft).revise!(user: users(:me), status: 'published')
    end
  end

  test 'publishing again after reverting to draft notifies only once' do
    chapter = chapters(:you_draft_on_my_map)

    chapter.revise!(user: users(:you), status: 'published')
    chapter.revise!(user: users(:you), status: 'draft')

    assert_no_difference 'Notification.count' do
      chapter.revise!(user: users(:you), status: 'published')
    end
  end

  test 'editing a published chapter notifies nobody' do
    assert_no_difference 'Notification.count' do
      chapters(:you_published_on_my_map).revise!(user: users(:you), title: 'A new title')
    end
  end

  test 'a failed notification rolls the publication back' do
    chapter = chapters(:you_draft_on_my_map)
    failing_create = lambda { |*|
      raise ActiveRecord::RecordNotSaved.new('failed', Notification.new)
    }

    Notification.stub :create!, failing_create do
      assert_raises(ActiveRecord::RecordNotSaved) do
        chapter.revise!(user: users(:you), status: 'published')
      end
    end

    assert_predicate chapter.reload, :draft?
  end

  test 'publishing a chapter whose map is gone notifies nobody' do
    chapter = chapters(:you_draft_on_my_map)
    chapter.map.destroy!

    assert_no_difference 'Notification.count' do
      chapter.reload.revise!(user: users(:you), status: 'published')
    end
  end
end
