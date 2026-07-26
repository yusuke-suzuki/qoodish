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
end
