require 'test_helper'

class BackfillChapterRevisionsTest < ActiveSupport::TestCase
  TASK = Rails.root.join('lib/tasks/backfill_chapter_revisions.rb').to_s

  test 'gives a chapter without a revision its first one' do
    chapter = detach_revision(chapters(:my_published))

    run_task

    revision = chapter.reload.current_revision

    assert_equal chapter.revisions.last, revision
    assert_equal chapter.title, revision.title
    assert_equal chapter.content, revision.content
    assert_equal chapter.map_features, revision.map_features
    assert_predicate revision, :published?
  end

  test 'records the draft status a chapter still holds' do
    chapter = detach_revision(chapters(:my_draft))

    run_task

    assert_predicate chapter.reload.current_revision, :draft?
  end

  test 'records the images the legacy imageable column holds' do
    chapter = detach_revision(chapters(:my_published))
    image = users(:me).owned_images.create!(
      imageable: chapter,
      url: 'https://imagedelivery.net/mockhash/chapter-backfill/public'
    )

    run_task

    assert_equal [image.id], chapter.reload.images.ids
  end

  test 'leaves the chapter last updated when it was' do
    chapter = detach_revision(chapters(:my_published))
    updated_at = chapter.updated_at

    run_task

    assert_equal updated_at, chapter.reload.updated_at
    assert_equal updated_at, chapter.current_revision.created_at
  end

  test 'a second run appends nothing' do
    detach_revision(chapters(:my_published))

    run_task

    assert_no_difference 'ChapterRevision.count' do
      run_task
    end
  end

  private

  def run_task
    capture_io { load TASK }
  end

  # The fixtures already carry a revision, so the state the backfill exists for
  # has to be restored first.
  def detach_revision(chapter)
    chapter.update_column(:current_revision_id, nil)
    chapter.revisions.destroy_all
    chapter
  end
end
