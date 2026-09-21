require 'test_helper'

class CommentTest < ActiveSupport::TestCase
  test 'image_variants delegates to commentable' do
    comment = comments(:one)
    assert_equal comment.commentable.image_variants, comment.image_variants
  end

  test 'body drops carriage returns on assignment' do
    comment = leave("First\r\nline")

    assert_equal "First\nline", comment.reload.body
  end

  test 'record! writes the first revision and points the comment at it' do
    comment = leave('Nice place')

    assert_equal 1, comment.revisions.count
    assert_equal comment.revisions.last, comment.current_revision
    assert_predicate comment, :published?
  end

  test 'revise! appends a revision and leaves the previous one untouched' do
    comment = comments(:one)
    previous = comment.current_revision

    comment.revise!(user: users(:me), body: 'Rewritten')

    assert_equal 'Rewritten', comment.reload.body
    assert_equal 2, comment.revisions.count
    assert_equal comment.revisions.last, comment.current_revision
    assert_equal 'This is a comment', previous.reload.body
  end

  test 'a revision cannot be rewritten' do
    revision = comments(:one).current_revision

    assert_raises(ActiveRecord::ReadonlyAttributeError) { revision.update!(body: 'rewritten') }
  end

  test 'body cannot be changed outside a revision' do
    comment = comments(:one)

    assert_raises(ActiveRecord::ReadOnlyRecord) { comment.update!(body: 'Rewritten') }
    assert_equal 'This is a comment', comment.reload.body
  end

  test 'a comment cannot be created outside a revision' do
    assert_raises(ActiveRecord::ReadOnlyRecord) do
      pins(:public_one).comments.create!(user: users(:me), body: 'Sneaked in')
    end
  end

  test 'discard! keeps the row and takes it off the pin' do
    comment = comments(:one)

    assert_no_difference 'Comment.count' do
      assert_difference -> { comment.revisions.count }, 1 do
        comment.discard!(user: users(:me))
      end
    end

    assert_predicate comment.reload, :deleted?
    assert_predicate comment.current_revision, :deleted?
    assert_not_includes pins(:public_one).comments.reload, comment
    assert_not_includes users(:me).comments.reload, comment
  end

  test 'the log keeps what a discarded comment said' do
    comment = comments(:one)

    comment.discard!(user: users(:me))

    assert_equal ['This is a comment', 'This is a comment'], comment.revisions.map(&:body)
    assert_equal %w[published deleted], comment.revisions.map(&:status)
  end

  test 'destroying the pin destroys the comments it discarded' do
    comments(:one).discard!(user: users(:me))

    assert_difference 'Comment.count', -2 do
      pins(:public_one).destroy!
    end
  end

  test 'erasing an account destroys the comments it discarded' do
    comments(:two).discard!(user: users(:you))

    assert_difference 'Comment.count', -1 do
      stub_identity_platform { users(:you).destroy! }
    end
  end

  test 'revising a comment does not reach for images' do
    comment = comments(:one)

    comment.revise!(user: users(:me), body: 'Edited')

    assert_not_respond_to comment.current_revision, :images
  end

  test 'destroying a comment takes its revisions with it' do
    comment = comments(:one)

    assert_difference 'CommentRevision.count', -1 do
      comment.destroy!
    end
  end

  private

  def leave(body)
    Comment.record!(user: users(:me), commentable: pins(:public_one), body: body)
  end
end
